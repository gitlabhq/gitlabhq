# frozen_string_literal: true

class LoggedOutMarketingHeaderExperiment < ApplicationExperiment
  # These default behaviors are overriden in ApplicationHelper and header
  # template partial
  control {}
  candidate {}
  variant(:trial_focused) {}
end
