require "grit"

module Network
  class Commit
    include ActionView::Helpers::TagHelper

    attr_reader :refs
    attr_accessor :time, :spaces, :parent_spaces

    def initialize(raw_commit, refs)
      @commit = ::Commit.new(raw_commit)
      @time = -1
      @spaces = []
      @parent_spaces = []
      @refs = refs || []
    end

    def method_missing(m, *args, &block)
      @commit.send(m, *args, &block)
    end

    def space
      if @spaces.size > 0
        @spaces.first
      else
        0
      end
    end

    def parents(map)
      @commit.parents.map do |p|
        if map.include?(p.id)
          map[p.id]
        end
      end
      .compact
    end
  end
end
