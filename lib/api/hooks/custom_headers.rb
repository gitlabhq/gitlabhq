# frozen_string_literal: true

module API
  module Hooks
    # rubocop: disable API/Base -- It is important that this re-usable module is not a Grape Instance, since it will be re-mounted.
    class CustomHeaders < ::Grape::API
      params do
        requires :hook_id, type: Integer, desc: 'The ID of the hook'
        requires :key, type: String, desc: 'The key of the custom header'
      end
      namespace ':hook_id/custom_headers' do
        desc 'Set a custom header'
        params do
          requires :value, type: String, desc: 'The value of the custom header'
        end
        put ":key" do
          hook = find_hook
          key = params.delete(:key)
          value = params.delete(:value)
          custom_headers = hook.custom_headers.merge(key => value)

          error!('Illegal key or value', 422) unless hook.update(custom_headers: custom_headers)

          status :no_content
        end

        desc 'Un-Set a custom header'
        delete ":key" do
          hook = find_hook
          key = params.delete(:key)
          not_found!('Custom header') unless hook.custom_headers.key?(key)

          vars = hook.custom_headers.reject { |k, _| k == key }

          error!('Could not unset custom header', 422) unless hook.update(custom_headers: vars)

          status :no_content
        end
      end
    end
    # rubocop: enable API/Base
  end
end
