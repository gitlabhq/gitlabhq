module Network
  class Commit
    include ActionView::Helpers::TagHelper

    attr_accessor :time, :spaces, :parent_spaces

    def initialize(raw_commit)
      @commit = raw_commit
      @time = -1
      @spaces = []
      @parent_spaces = []
    end

    def method_missing(m, *args, &block)
      @commit.__send__(m, *args, &block) # rubocop:disable GitlabSecurity/PublicSend
    end

    def space
      if @spaces.size > 0
        @spaces.first
      else
        0
      end
    end

    def parents(map)
      map.values_at(*@commit.parent_ids).compact
    end
  end
end
