# frozen_string_literal: true

class WebHook < ApplicationRecord
  include WebHooks::Hook
end
