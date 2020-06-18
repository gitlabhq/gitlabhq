# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      module Bridge
        class Failed < Status::Build::Failed
          private

          def failure_reason_message
            [
              self.class.reasons.fetch(subject.failure_reason.to_sym),
              subject.options[:downstream_errors]
            ].flatten.compact.join(', ')
          end
        end
      end
    end
  end
end
