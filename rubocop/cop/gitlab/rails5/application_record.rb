# This cop checks for the `ActiveRecord::Base` constant calls. The `ApplicationRecord` should be used instead.
# This is a part of rails5 migration process: https://gitlab.com/gitlab-org/gitlab-ce/issues/14286
#
# This cop should be removed when upgraded to rails 5.0 (if no longer needed to explicitly check for `ActiveRecord::Base`).
#
# Bad:
#   class User < ActiveRecord::Base
#     def something
#       ::ActiveRecord::Base.connection(...)
#     end
#   end
#
# Good:
#   class User < ApplicationRecord
#     def something
#       ::ApplicationRecord.connection(...)
#     end
#   end

module RuboCop
  module Cop
    module Gitlab
      module Rails5
        class ApplicationRecord < RuboCop::Cop::Cop
          ILLEGAL_CLASS_NAME = "ActiveRecord::Base".freeze
          LEGAL_CLASS_NAME   = "ApplicationRecord".freeze

          MSG = "Use `#{LEGAL_CLASS_NAME}` instead of `#{ILLEGAL_CLASS_NAME}`".freeze

          def_node_matcher :includes_active_record_base?, <<-PATTERN
            (const
              (const ${nil? cbase} :ActiveRecord) :Base)
          PATTERN

          def on_const(node)
            includes_active_record_base?(node) { add_offense(node) }
          end

          def autocorrect(node)
            lambda do |corrector|
              top_level = node.each_node(:cbase).any? ? "::" : ""

              corrector.replace(node.loc.expression, "#{top_level}#{LEGAL_CLASS_NAME}")
            end
          end
        end
      end
    end
  end
end
