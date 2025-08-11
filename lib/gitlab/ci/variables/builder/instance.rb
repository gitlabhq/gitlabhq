# frozen_string_literal: true

module Gitlab
  module Ci
    module Variables
      class Builder
        class Instance
          include Gitlab::Utils::StrongMemoize

          def secret_variables(protected_ref: false, only: nil)
            variables = if protected_ref
                          ::Ci::InstanceVariable.all_cached
                        else
                          ::Ci::InstanceVariable.unprotected_cached
                        end

            # Due to caching logic these variables are an array so we can't use ActiveRecord.where
            variables = variables.filter { |v| only.nil? || v.key.in?(only) }

            Gitlab::Ci::Variables::Collection.new(variables)
          end
        end
      end
    end
  end
end
