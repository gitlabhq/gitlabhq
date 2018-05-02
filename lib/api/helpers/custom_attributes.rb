module API
  module Helpers
    module CustomAttributes
      extend ActiveSupport::Concern

      included do
        helpers do
          params :with_custom_attributes do
            optional :with_custom_attributes, type: Boolean, default: false, desc: 'Include custom attributes in the response'

            optional :custom_attributes, type: Hash,
                                         desc: 'Filter with custom attributes'
          end

          def with_custom_attributes(collection_or_resource, options = {})
            options = options.merge(
              with_custom_attributes: params[:with_custom_attributes] &&
                can?(current_user, :read_custom_attribute)
            )

            if options[:with_custom_attributes] && collection_or_resource.is_a?(ActiveRecord::Relation)
              collection_or_resource = collection_or_resource.includes(:custom_attributes)
            end

            [collection_or_resource, options]
          end
        end
      end
    end
  end
end
