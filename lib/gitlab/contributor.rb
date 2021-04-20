# frozen_string_literal: true

module Gitlab
  class Contributor
    attr_accessor :email, :name, :commits, :additions, :deletions

    def initialize
      @commits = 0
      @additions = 0
      @deletions = 0
    end
  end
end
