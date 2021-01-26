# frozen_string_literal: true

module Gitlab
  module Changelog
    module Template
      # Compiler is used for turning a minimal user templating language into an
      # ERB template, without giving the user access to run arbitrary code.
      #
      # The template syntax is deliberately made as minimal as possible, and
      # only supports the following:
      #
      # * Printing a value
      # * Iterating over collections
      # * if/else
      #
      # The syntax looks as follows:
      #
      #     {% each users %}
      #
      #     Name: {{user}}
      #     Likes cats: {% if likes_cats %}yes{% else %}no{% end %}
      #
      #     {% end %}
      #
      # Newlines can be escaped by ending a line with a backslash. So this:
      #
      #     foo \
      #     bar
      #
      # Is the same as this:
      #
      #     foo bar
      #
      # Templates are compiled into ERB templates, while taking care to make
      # sure the user can't run arbitrary code. By using ERB we can let it do
      # the heavy lifting of rendering data; all we need to provide is a
      # translation layer.
      #
      # # Security
      #
      # The template syntax this compiler exposes is safe to be used by
      # untrusted users. Not only are they unable to run arbitrary code, the
      # compiler also enforces a limit on the integer sizes and the number of
      # nested loops. ERB tags added by the user are also disabled.
      class Compiler
        # A pattern to match a single integer, with an upper size limit.
        #
        # We enforce a limit of 10 digits (= a 32 bits integer) so users can't
        # trigger the allocation of infinitely large bignums, or trigger
        # RangeError errors when using such integers to access an array value.
        INTEGER = /^\d{1,10}$/.freeze

        # The name/path of a variable, such as `user.address.city`.
        #
        # It's important that this regular expression _doesn't_ allow for
        # anything but letters, numbers, and underscores, otherwise a user may
        # use those to "escape" our template and run arbirtary Ruby code. For
        # example, take this variable:
        #
        #     {{') ::Kernel.exit #'}}
        #
        # This would then be compiled into:
        #
        #     <%= read(variables, '') ::Kernel.exit #'') %>
        #
        # Restricting the allowed characters makes this impossible.
        VAR_NAME = /([\w\.]+)/.freeze

        # A variable tag, such as `{{username}}`.
        VAR = /{{ \s* #{VAR_NAME} \s* }}/x.freeze

        # The opening tag for a statement.
        STM_START = /{% \s*/x.freeze

        # The closing tag for a statement.
        STM_END = /\s* %}/x.freeze

        # A regular `end` closing tag.
        NORMAL_END = /#{STM_START} end #{STM_END}/x.freeze

        # An `end` closing tag on its own line, without any non-whitespace
        # preceding or following it.
        #
        # These tags need some special care to make it easier to control
        # whitespace.
        LONELY_END = /^\s*#{NORMAL_END}\s$/x.freeze

        # An `else` tag.
        ELSE = /#{STM_START} else #{STM_END}/x.freeze

        # The start of an `each` tag.
        EACH = /#{STM_START} each \s+ #{VAR_NAME} #{STM_END}/x.freeze

        # The start of an `if` tag.
        IF = /#{STM_START} if \s+ #{VAR_NAME} #{STM_END}/x.freeze

        # The pattern to use for escaping newlines.
        ESCAPED_NEWLINE = /\\\n$/.freeze

        # The start tag for ERB tags. These tags will be escaped, preventing
        # users FROM USING erb DIRECTLY.
        ERB_START_TAG = '<%'

        def compile(template)
          transformed_lines = ['<% it = variables %>']

          template.each_line { |line| transformed_lines << transform(line) }
          Template.new(transformed_lines.join)
        end

        def transform(line)
          line.gsub!(ESCAPED_NEWLINE, '')
          line.gsub!(ERB_START_TAG, '<%%')

          # This replacement ensures that "end" blocks on their own lines
          # don't add extra newlines. Using an ERB -%> tag sadly swallows too
          # many newlines.
          line.gsub!(LONELY_END, '<% end %>')
          line.gsub!(NORMAL_END, '<% end %>')
          line.gsub!(ELSE, '<% else -%>')

          line.gsub!(EACH) do
            # No, `it; variables` isn't a syntax error. Using `;` marks
            # `variables` as block-local, making it possible to re-assign it
            # without affecting outer definitions of this variable. We use
            # this to scope template variables to the right input Hash.
            "<% each(#{read_path(Regexp.last_match(1))}) do |it; variables| -%><% variables = it -%>"
          end

          line.gsub!(IF) { "<% if truthy?(#{read_path(Regexp.last_match(1))}) -%>" }
          line.gsub!(VAR) { "<%= #{read_path(Regexp.last_match(1))} %>" }
          line
        end

        def read_path(path)
          return path if path == 'it'

          args = path.split('.')
          args.map! { |arg| arg.match?(INTEGER) ? "#{arg}" : "'#{arg}'" }

          "read(variables, #{args.join(', ')})"
        end
      end
    end
  end
end
