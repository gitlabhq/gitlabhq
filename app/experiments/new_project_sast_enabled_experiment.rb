# frozen_string_literal: true

class NewProjectSastEnabledExperiment < ApplicationExperiment
  control { }
  variant(:candidate) { }
  variant(:free_indicator) { }
  variant(:unchecked_candidate) { }
  variant(:unchecked_free_indicator) { }

  def publish(*args)
    super

    publish_to_database
  end
end
