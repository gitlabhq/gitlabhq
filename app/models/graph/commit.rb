require "grit"

module Graph
  class Commit
    include ActionView::Helpers::TagHelper

    attr_accessor :time, :spaces, :refs, :parent_spaces

    def initialize(commit)
      @_commit = commit
      @time = -1
      @spaces = []
      @parent_spaces = []
    end

    def method_missing(m, *args, &block)
      @_commit.send(m, *args, &block)
    end

    def add_refs(ref_cache, repo)
      if ref_cache.empty?
        repo.refs.each do |ref|
          ref_cache[ref.commit.id] ||= []
          ref_cache[ref.commit.id] << ref
        end
      end
      @refs = ref_cache[@_commit.id] if ref_cache.include?(@_commit.id)
      @refs ||= []
    end

    def space
      if @spaces.size > 0
        @spaces.first
      else
        0
      end
    end
  end
end
