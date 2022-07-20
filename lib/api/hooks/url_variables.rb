# frozen_string_literal: true

module API
  module Hooks
    # It is important that this re-usable module is not a Grape Instance,
    # since it will be re-mounted.
    # rubocop: disable API/Base
    class UrlVariables < ::Grape::API
      params do
        requires :hook_id, type: Integer, desc: 'The ID of the hook'
        requires :key, type: String, desc: 'The key of the variable'
      end
      namespace ':hook_id/url_variables' do
        desc 'Set a url variable'
        params do
          requires :value, type: String, desc: 'The value of the variable'
        end
        put ":key" do
          hook = find_hook
          key = params.delete(:key)
          value = params.delete(:value)
          vars = hook.url_variables.merge(key => value)

          error!('Illegal key or value', 422) unless hook.update(url_variables: vars)

          status :no_content
        end

        desc 'Un-Set a url variable'
        delete ":key" do
          hook = find_hook
          key = params.delete(:key)
          not_found!('URL variable') unless hook.url_variables.key?(key)

          vars = hook.url_variables.reject { _1 == key }

          error!('Could not unset variable', 422) unless hook.update(url_variables: vars)

          status :no_content
        end
      end
    end
    # rubocop: enable API/Base
  end
end
