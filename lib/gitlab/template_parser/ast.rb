# frozen_string_literal: true

module Gitlab
  module TemplateParser
    # AST nodes to evaluate when rendering a template.
    #
    # Evaluating an AST is done by walking over the nodes and calling
    # `evaluate`. This method takes two arguments:
    #
    # 1. An instance of `EvalState`, used for tracking data such as the number
    #    of nested loops.
    # 2. An object used as the data for the current scope. This can be an Array,
    #    Hash, String, or something else. It's up to the AST node to determine
    #    what to do with it.
    #
    # While tree walking interpreters (such as implemented here) aren't usually
    # the fastest type of interpreter, they are:
    #
    # 1. Fast enough for our use case
    # 2. Easy to implement and maintain
    #
    # In addition, our AST interpreter doesn't allow for arbitrary code
    # execution, unlike existing template engines such as Mustache
    # (https://github.com/mustache/mustache/issues/244) or ERB.
    #
    # Our interpreter also takes care of limiting the number of nested loops.
    # And unlike Liquid, our interpreter is much smaller and thus has a smaller
    # attack surface. Liquid isn't without its share of issues, such as
    # https://github.com/Shopify/liquid/pull/1071.
    #
    # We also evaluated using Handlebars using the project
    # https://github.com/SmartBear/ruby-handlebars. Sadly, this implementation
    # of Handlebars doesn't support control of whitespace
    # (https://github.com/SmartBear/ruby-handlebars/issues/37), and the project
    # didn't appear to be maintained that much.
    #
    # This doesn't mean these template engines aren't good, instead it means
    # they won't work for our use case. For more information, refer to the
    # comment https://gitlab.com/gitlab-org/gitlab/-/merge_requests/50063#note_469293322.
    module AST
      # An identifier in a selector.
      Identifier = Struct.new(:name) do
        def evaluate(state, data)
          return data if name == 'it'

          data[name] if data.is_a?(Hash)
        end
      end

      # An integer used in a selector.
      Integer = Struct.new(:value) do
        def evaluate(state, data)
          data[value] if data.is_a?(Array)
        end
      end

      # A selector used for loading a value.
      Selector = Struct.new(:steps) do
        def evaluate(state, data)
          steps.reduce(data) do |current, step|
            break if current.nil?

            step.evaluate(state, current)
          end
        end
      end

      # A tag used for displaying a value in the output.
      Variable = Struct.new(:selector) do
        def evaluate(state, data)
          selector.evaluate(state, data).to_s
        end
      end

      # A collection of zero or more expressions.
      Expressions = Struct.new(:nodes) do
        def evaluate(state, data)
          nodes.map { |node| node.evaluate(state, data) }.join('')
        end
      end

      # A single text node.
      Text = Struct.new(:text) do
        def evaluate(*)
          text
        end
      end

      # An `if` expression, with an optional `else` clause.
      If = Struct.new(:condition, :true_body, :false_body) do
        def evaluate(state, data)
          result =
            if truthy?(condition.evaluate(state, data))
              true_body.evaluate(state, data)
            elsif false_body
              false_body.evaluate(state, data)
            end

          result.to_s
        end

        def truthy?(value)
          # We treat empty collections and such as false, removing the need for
          # some sort of `if length(x) > 0` expression.
          value.respond_to?(:empty?) ? !value.empty? : !!value
        end
      end

      # An `each` expression.
      Each = Struct.new(:collection, :body) do
        def evaluate(state, data)
          values = collection.evaluate(state, data)

          return '' unless values.respond_to?(:each)

          # While unlikely to happen, it's possible users attempt to nest many
          # loops in order to negatively impact the GitLab instance. To make
          # this more difficult, we limit the number of nested loops a user can
          # create.
          state.enter_loop do
            values.map { |value| body.evaluate(state, value) }.join('')
          end
        end
      end

      # A class for transforming a raw Parslet AST into a more structured/easier
      # to work with AST.
      #
      # For more information about Parslet transformations, refer to the
      # documentation at http://kschiess.github.io/parslet/transform.html.
      class Transformer < Parslet::Transform
        rule(ident: simple(:name)) { Identifier.new(name.to_s) }
        rule(int: simple(:name)) { Integer.new(name.to_i) }
        rule(text: simple(:text)) { Text.new(text.to_s) }
        rule(exprs: subtree(:nodes)) { Expressions.new(nodes) }
        rule(selector: sequence(:steps)) { Selector.new(steps) }
        rule(selector: simple(:step)) { Selector.new([step]) }
        rule(variable: simple(:selector)) { Variable.new(selector) }
        rule(each: simple(:values), body: simple(:body)) do
          Each.new(values, body)
        end

        rule(if: simple(:cond), true_body: simple(:true_body)) do
          If.new(cond, true_body)
        end

        rule(
          if: simple(:cond),
          true_body: simple(:true_body),
          false_body: simple(:false_body)
        ) do
          If.new(cond, true_body, false_body)
        end
      end
    end
  end
end
