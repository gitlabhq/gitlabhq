# frozen_string_literal: true

module API
  module CustomAttributesEndpoints
    extend ActiveSupport::Concern

    included do
      attributable_class = name.demodulize.singularize
      attributable_key = attributable_class.underscore
      attributable_name = attributable_class.humanize(capitalize: false)
      attributable_finder = "find_#{attributable_key}"
      boundary_type = if attributable_key == 'user'
                        :instance
                      else
                        attributable_key.to_sym
                      end

      helpers ::API::Helpers::CustomAttributesHelpers

      helpers do
        params :custom_attributes_key do
          requires :key, type: String, desc: 'The key of the custom attribute'
        end
      end

      params do
        requires :id, types: [String, Integer], desc: "The ID or URL-encoded path of the #{attributable_name}"
      end
      desc "List all custom attributes for a #{attributable_name}" do
        detail "Lists all custom attributes for a specified #{attributable_name}."
        success Entities::CustomAttribute
        tags ['custom_attributes']
      end
      route_setting :authorization, permissions: :read_custom_attribute, boundary_type: boundary_type
      get ':id/custom_attributes' do
        resource = find_resource(attributable_finder, params[:id])
        authorize! :read_custom_attribute

        present resource.custom_attributes, with: Entities::CustomAttribute
      end

      desc "Retrieve a custom attribute for a #{attributable_name}" do
        detail "Retrieves a specified custom attribute for a #{attributable_name}."
        success Entities::CustomAttribute
        tags ['custom_attributes']
      end
      params do
        use :custom_attributes_key
      end
      route_setting :authorization, permissions: :read_custom_attribute, boundary_type: boundary_type
      # rubocop: disable CodeReuse/ActiveRecord
      get ':id/custom_attributes/:key' do
        resource = find_resource(attributable_finder, params[:id])
        authorize! :read_custom_attribute

        custom_attribute = resource.custom_attributes.find_by!(key: params[:key])

        present custom_attribute, with: Entities::CustomAttribute
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc "Creates or updates a custom attribute for a #{attributable_name}" do
        detail "Creates or updates a custom attribute for a specified #{attributable_name}. " \
          "If the attribute already exists, it is updated, otherwise a new attribute is created."
        success Entities::CustomAttribute
        tags ['custom_attributes']
      end
      params do
        use :custom_attributes_key
        requires :value, type: String, desc: 'The value of the custom attribute'
      end
      route_setting :authorization, permissions: :update_custom_attribute, boundary_type: boundary_type
      put ':id/custom_attributes/:key' do
        resource = find_resource(attributable_finder, params[:id])
        authorize! :update_custom_attribute

        result = ::CustomAttributes::UpsertService.new(
          resource,
          current_user: current_user,
          key: params[:key],
          value: params[:value]
        ).execute

        if result.error?
          forbidden! if result.cause.unauthorized?
          render_api_error!(result.message, :bad_request)
        end

        present result[:custom_attribute], with: Entities::CustomAttribute
      end

      desc "Delete a custom attribute for a #{attributable_name}" do
        detail "Deletes a specified custom attribute for a #{attributable_name}."
        success code: 204
        tags ['custom_attributes']
      end
      params do
        use :custom_attributes_key
      end
      route_setting :authorization, permissions: :delete_custom_attribute, boundary_type: boundary_type
      delete ':id/custom_attributes/:key' do
        resource = find_resource(attributable_finder, params[:id])
        authorize! :update_custom_attribute

        result = ::CustomAttributes::DestroyService.new(resource, current_user: current_user, key: params[:key]).execute

        not_found!('Custom attribute') if result.error?

        no_content!
      end
    end
  end
end
