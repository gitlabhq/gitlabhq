require "grit"

module Graph
  class Commit
    include ActionView::Helpers::TagHelper

    attr_accessor :time, :spaces, :refs, :parent_spaces, :icon

    def initialize(commit)
      @_commit = commit
      @time = -1
      @spaces = []
      @parent_spaces = []
    end

    def method_missing(m, *args, &block)
      @_commit.send(m, *args, &block)
    end

    def to_graph_hash
      h = {}
      h[:parents] = self.parents.collect do |p|
        [p.id,0,0]
      end
      h[:author]  = {
        name: author.name,
        email: author.email,
        icon: icon
      }
      h[:time]    = time
      h[:space]   = spaces.first
      h[:parent_spaces]   = parent_spaces
      h[:refs]    = refs.collect{|r|r.name}.join(" ") unless refs.nil?
      h[:id]      = sha
      h[:date]    = date
      h[:message] = message
      h
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
