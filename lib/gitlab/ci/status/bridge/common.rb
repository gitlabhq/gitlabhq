# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      module Bridge
        module Common
          def label
            subject.description
          end

          def has_details?
            false
          end

          def has_action?
            false
          end

          def details_path
          end
        end
      end
    end
  end
end
