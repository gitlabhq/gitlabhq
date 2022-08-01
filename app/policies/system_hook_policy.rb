# frozen_string_literal: true

class SystemHookPolicy < ::BasePolicy
  rule { admin }.policy do
    enable :read_web_hook
    enable :destroy_web_hook
  end
end
