# frozen_string_literal: true

module API
  module Hooks
    # It is important that this re-usable module is not a Grape Instance,
    # since it will be re-mounted.
    # rubocop: disable API/Base
    class Test < ::Grape::API
      params do
        requires :hook_id, type: Integer, desc: 'The ID of the hook'
      end
      post ":hook_id" do
        hook = find_hook
        data = configuration[:data].dup
        hook.execute(data, configuration[:kind])
        data
      end
    end
    # rubocop: enable API/Base
  end
end
