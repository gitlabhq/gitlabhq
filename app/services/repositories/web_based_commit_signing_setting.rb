# frozen_string_literal: true

module Repositories
  class WebBasedCommitSigningSetting
    def initialize(repository)
      @repository = repository
    end
    attr_reader :repository

    def sign_commits?
      true
    end
  end
end
Repositories::WebBasedCommitSigningSetting.prepend_mod
