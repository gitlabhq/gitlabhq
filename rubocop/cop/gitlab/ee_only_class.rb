# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      class EeOnlyClass < RuboCop::Cop::Base
        # Cop that checks for incorrect placement of classes in the ee/**/ee subdirectories.
        #
        # see https://docs.gitlab.com/ee/development/ee_features.html#extend-ce-features-with-ee-backend-code
        #
        #  # bad
        #  # filename: ee/app/services/ee/null_notification_service.rb
        #  module EE
        #    class NullNotificationService
        #    end
        #  end
        #
        #  # good
        #  # filename: ee/app/services/null_notification_service.rb
        #  class NullNotificationService
        #  end
        #
        MSG = <<~TEXT
          This area is meant for extending CE functionality with modules.
          It is likely this file should be removed from the sub ee directory it is currently in. Please read this
          for the rationale behind it:

          https://docs.gitlab.com/ee/development/ee_features.html#extend-ce-features-with-ee-backend-code
        TEXT

        def on_class(node)
          # If class name matches file name - offense, if not, then no offense as it is valid
          # to create classes inside a module.
          return if to_class_name(File.basename(processed_source.file_path)) != node.loc.name.source

          add_offense(node)
        end

        private

        def to_class_name(basename)
          # Our case here is likely purely for `.rb` files, but we'll remain flexible in general for
          # haml_lint, .erb, etc
          # Not using ActiveSupport since we do not want to declare that as a dependency on this generic ruby concept.
          words = basename.sub(/\..*/, '').split('_')
          words.map(&:capitalize).join
        end
      end
    end
  end
end
