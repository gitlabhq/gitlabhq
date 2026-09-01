# frozen_string_literal: true

class WebHook < ApplicationRecord
  include FromUnion
  include WebHooks::Hook
end
