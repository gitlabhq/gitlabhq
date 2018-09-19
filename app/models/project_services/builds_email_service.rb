# frozen_string_literal: true

# This class is to be removed with 9.1
# We should also by then remove BuildsEmailService from database
class BuildsEmailService < Service
  def self.to_param
    'builds_email'
  end

  def self.supported_events
    %w[]
  end
end
