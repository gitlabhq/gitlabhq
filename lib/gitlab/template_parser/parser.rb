# frozen_string_literal: true

module Gitlab
  module TemplateParser
    # A parser for a simple template syntax, used for example to generate changelogs.
    #
    # As a quick primer on the template syntax, a basic template looks like
    # this:
    #
    #     {% each users %}
    #     Name: {{name}}
    #     Age: {{age}}
    #
    #     {% if birthday %}
    #     This user is celebrating their birthday today! Yay!
    #     {% end %}
    #     {% end %}
    #
    # For more information, refer to the Parslet documentation found at
    # http://kschiess.github.io/parslet/.
    class Parser < Parslet::Parser
      root(:exprs)

      rule(:exprs) do
        (
          variable | if_expr | each_expr | escaped | text | newline
        ).repeat.as(:exprs)
      end

      rule(:space) { match('[ \\t]') }
      rule(:whitespace) { match('\s').repeat }
      rule(:lf) { str("\n") }
      rule(:newline) { lf.as(:text) }

      # Escaped newlines are ignored, allowing the user to control the
      # whitespace in the output. All other escape sequences are treated as
      # literal text.
      #
      # For example, this:
      #
      #     foo \
      #     bar
      #
      # Is parsed into this:
      #
      #     foo bar
      rule(:escaped) do
        backslash = str('\\')

        (backslash >> lf).ignore | (backslash >> chars).as(:text)
      end

      # A sequence of regular characters, with the exception of newlines and
      # escaped newlines.
      rule(:chars) do
        char = match("[^{\\\\\n]")

        # The rules here are such that we do treat single curly braces or
        # non-opening tags (e.g. `{foo}`) as text, but not opening tags
        # themselves (e.g. `{{`).
        (
          char.repeat(1) | (curly_open >> (curly_open | percent).absent?)
        ).repeat(1)
      end

      rule(:text) { chars.as(:text) }

      # An integer, limited to 10 digits (= a 32 bits integer).
      #
      # The size is limited to prevents users from creating integers that are
      # too large, as this may result in runtime errors.
      rule(:integer) { match('\d').repeat(1, 10).as(:int) }

      # An identifier to look up in a data structure.
      #
      # We only support simple ASCII identifiers as we simply don't have a need
      # for more complex identifiers (e.g. those containing multibyte
      # characters).
      rule(:ident) { match('[a-zA-Z_]').repeat(1).as(:ident) }

      # A selector is used for reading a value, consisting of one or more
      # "steps".
      #
      # Examples:
      #
      #     name
      #     users.0.name
      #     0
      #     it
      rule(:selector) do
        step = ident | integer

        whitespace >>
          (step >> (str('.') >> step).repeat).as(:selector) >>
          whitespace
      end

      rule(:curly_open) { str('{') }
      rule(:curly_close) { str('}') }
      rule(:percent) { str('%') }

      # A variable tag.
      #
      # Examples:
      #
      #     {{name}}
      #     {{users.0.name}}
      rule(:variable) do
        curly_open.repeat(2) >> selector.as(:variable) >> curly_close.repeat(2)
      end

      rule(:expr_open) { curly_open >> percent >> whitespace }
      rule(:expr_close) do
        # Since whitespace control is important (as Markdown is whitespace
        # sensitive), we default to stripping a newline that follows a %} tag.
        # This is less annoying compared to having to opt-in to this behaviour.
        whitespace >> percent >> curly_close >> lf.maybe.ignore
      end

      rule(:end_tag) { expr_open >> str('end') >> expr_close }

      # An `if` expression, with an optional `else` clause.
      #
      # Examples:
      #
      #     {% if foo %}
      #     yes
      #     {% end %}
      #
      #     {% if foo %}
      #     yes
      #     {% else %}
      #     no
      #     {% end %}
      rule(:if_expr) do
        else_tag =
          expr_open >> str('else') >> expr_close >> exprs.as(:false_body)

        expr_open >>
          str('if') >>
          space.repeat(1) >>
          selector.as(:if) >>
          expr_close >>
          exprs.as(:true_body) >>
          else_tag.maybe >>
          end_tag
      end

      # An `each` expression, used for iterating over collections.
      #
      # Example:
      #
      #     {% each users %}
      #     * {{name}}
      #     {% end %}
      rule(:each_expr) do
        expr_open >>
          str('each') >>
          space.repeat(1) >>
          selector.as(:each) >>
          expr_close >>
          exprs.as(:body) >>
          end_tag
      end

      def parse_and_transform(input)
        Timeout.timeout(2.seconds) { AST::Transformer.new.apply(parse(input)) }
      rescue Parslet::ParseFailed => ex
        # We raise a custom error so it's easier to catch different parser
        # related errors. In addition, this ensures the caller of this method
        # doesn't depend on a Parslet specific error class.
        raise Error, "Failed to parse the template: #{ex.message}"
      rescue Timeout::Error
        raise Error, 'Template parser timeout. Consider reducing the size of the template'
      end
    end
  end
end
