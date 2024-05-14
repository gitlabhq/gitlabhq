# frozen_string_literal: true

class SystemHookPolicy < ::BasePolicy
  delegate { :global }
end
