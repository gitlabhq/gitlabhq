module EE
  module Gitlab
    module Auth
      module Saml
        module Config
          extend ActiveSupport::Concern

          class_methods do
            def auditor_groups
              options[:auditor_groups].is_a?(Array) ? options[:auditor_groups] : []
            end

            def required_groups
              Array(options[:required_groups])
            end
          end
        end
      end
    end
  end
end
