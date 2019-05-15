# frozen_string_literal: true

# Add methods used by the projects API
module ProjectAPICompatibility
  extend ActiveSupport::Concern

  def build_git_strategy=(value)
    write_attribute(:build_allow_git_fetch, value == 'fetch')
  end
end
