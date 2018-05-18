module EE
  module Gitlab
    module Auth
      module Saml
        module Config
          extend ActiveSupport::Concern

          class_methods do
            def required_groups
              Array(options[:required_groups])
            end
          end
        end
      end
    end
  end
end
