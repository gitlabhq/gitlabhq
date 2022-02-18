# frozen_string_literal: true

module Gitlab
  module Ci
    module Variables
      class Builder
        class Instance
          include Gitlab::Utils::StrongMemoize

          def secret_variables(protected_ref: false)
            variables = if protected_ref
                          ::Ci::InstanceVariable.all_cached
                        else
                          ::Ci::InstanceVariable.unprotected_cached
                        end

            Gitlab::Ci::Variables::Collection.new(variables)
          end
        end
      end
    end
  end
end
