module API
  module CustomAttributesEndpoints
    extend ActiveSupport::Concern

    included do
      attributable_class = name.demodulize.singularize
      attributable_key = attributable_class.underscore
      attributable_name = attributable_class.humanize(capitalize: false)
      attributable_finder = "find_#{attributable_key}"

      helpers do
        params :custom_attributes_key do
          requires :key, type: String, desc: 'The key of the custom attribute'
        end
      end

      desc "Get all custom attributes on a #{attributable_name}" do
        success Entities::CustomAttribute
      end
      get ':id/custom_attributes' do
        resource = public_send(attributable_finder, params[:id]) # rubocop:disable GitlabSecurity/PublicSend
        authorize! :read_custom_attribute

        present resource.custom_attributes, with: Entities::CustomAttribute
      end

      desc "Get a custom attribute on a #{attributable_name}" do
        success Entities::CustomAttribute
      end
      params do
        use :custom_attributes_key
      end
      get ':id/custom_attributes/:key' do
        resource = public_send(attributable_finder, params[:id]) # rubocop:disable GitlabSecurity/PublicSend
        authorize! :read_custom_attribute

        custom_attribute = resource.custom_attributes.find_by!(key: params[:key])

        present custom_attribute, with: Entities::CustomAttribute
      end

      desc "Set a custom attribute on a #{attributable_name}"
      params do
        use :custom_attributes_key
        requires :value, type: String, desc: 'The value of the custom attribute'
      end
      put ':id/custom_attributes/:key' do
        resource = public_send(attributable_finder, params[:id]) # rubocop:disable GitlabSecurity/PublicSend
        authorize! :update_custom_attribute

        custom_attribute = resource.custom_attributes
          .find_or_initialize_by(key: params[:key])

        custom_attribute.update(value: params[:value])

        if custom_attribute.valid?
          present custom_attribute, with: Entities::CustomAttribute
        else
          render_validation_error!(custom_attribute)
        end
      end

      desc "Delete a custom attribute on a #{attributable_name}"
      params do
        use :custom_attributes_key
      end
      delete ':id/custom_attributes/:key' do
        resource = public_send(attributable_finder, params[:id]) # rubocop:disable GitlabSecurity/PublicSend
        authorize! :update_custom_attribute

        resource.custom_attributes.find_by!(key: params[:key]).destroy

        status 204
      end
    end
  end
end
