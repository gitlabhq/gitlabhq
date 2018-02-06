module Gitlab
  class Contributor
    attr_accessor :email, :name, :commits, :additions, :deletions

    def initialize
      @commits, @additions, @deletions = 0, 0, 0
    end
  end
end
