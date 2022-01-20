# frozen_string_literal: true

module Gitlab
  module WebHooks
    module RecursionDetection
      class UUID
        HEADER = "#{::Gitlab::WebHooks::GITLAB_EVENT_HEADER}-UUID"

        include Singleton

        attr_accessor :request_uuid

        def initialize
          self.new_uuids_for_hooks = {}
        end

        class << self
          # Back the Singleton with RequestStore so it is isolated to this request.
          def instance
            Gitlab::SafeRequestStore[:web_hook_recursion_detection_uuid] ||= new
          end
        end

        # Returns a UUID, which will be either:
        #
        #   - The UUID that was recycled from the request headers if the request was made by a webhook.
        #   - A new UUID initialized for the webhook.
        def uuid_for_hook(hook)
          request_uuid || new_uuid_for_hook(hook)
        end

        def header(hook)
          { HEADER => uuid_for_hook(hook) }
        end

        private

        attr_accessor :new_uuids_for_hooks

        def new_uuid_for_hook(hook)
          new_uuids_for_hooks[hook.id] ||= SecureRandom.uuid
        end
      end
    end
  end
end
