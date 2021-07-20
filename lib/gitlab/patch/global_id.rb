# frozen_string_literal: true

# To support GlobalID arguments that present a model with its old "deprecated" name
# we alter GlobalID so it will correctly find the record with its new model name.
module Gitlab
  module Patch
    module GlobalId
      def initialize(gid, options = {})
        super

        if deprecation = Gitlab::GlobalId::Deprecations.deprecation_for(model_name)
          @new_model_name = deprecation.new_model_name
        end
      end

      def model_name
        new_model_name || super
      end

      private

      attr_reader :new_model_name
    end
  end
end
