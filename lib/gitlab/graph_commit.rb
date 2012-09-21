require "grit"

module Gitlab
  class GraphCommit
    attr_accessor :time, :space
    attr_accessor :refs

    include ActionView::Helpers::TagHelper

    def self.to_graph(project)
      @repo = project.repo
      commits = Grit::Commit.find_all(@repo, nil, {max_count: 650})

      ref_cache = {}

      commits.map! {|c| GraphCommit.new(Commit.new(c))}
      commits.each { |commit| commit.add_refs(ref_cache, @repo) }

      days = GraphCommit.index_commits(commits)
      @days_json = days.compact.collect{|d| [d.day, d.strftime("%b")] }.to_json
      @commits_json = commits.map(&:to_graph_hash).to_json

      return @days_json, @commits_json
    end

    # Method is adding time and space on the
    # list of commits. As well as returns date list
    # corelated with time set on commits.
    #
    # @param [Array<GraphCommit>] comits to index
    #
    # @return [Array<TimeDate>] list of commit dates corelated with time on commits
    def self.index_commits(commits)
      days, heads = [], []
      map = {}

      commits.reverse.each_with_index do |c,i|
        c.time = i
        days[i] = c.committed_date
        map[c.id] = c
        heads += c.refs unless c.refs.nil?
      end

      heads.select!{|h| h.is_a? Grit::Head or h.is_a? Grit::Remote}
      # sort heads so the master is top and current branches are closer
      heads.sort! do |a,b|
        if a.name == "master"
          -1
        elsif b.name == "master"
          1
        else
          b.commit.committed_date <=> a.commit.committed_date
        end
      end

      @_reserved = {}
      days.each_index do |i|
        @_reserved[i] = []
      end

      heads.each do |h|
        if map.include? h.commit.id then
          place_chain(map[h.commit.id], map)
        end
      end
      days
    end

    # Add space mark on commit and its parents
    #
    # @param [GraphCommit] the commit object.
    # @param [Hash<String,GraphCommit>] map of commits
    def self.place_chain(commit, map, parent_time = nil)
      leaves = take_left_leaves(commit, map)
      if leaves.empty? then
        return
      end
      space = find_free_space(leaves.last.time..leaves.first.time)
      leaves.each{|l| l.space = space}
      # and mark it as reserved
      min_time = leaves.last.time
      parents = leaves.last.parents.collect
      parents.each do |p|
        if map.include? p.id then
          parent = map[p.id]
          if parent.time < min_time then
            min_time = parent.time
          end
        end
      end
      if parent_time.nil? then
        max_time = leaves.first.time
      else
        max_time = parent_time - 1
      end
      mark_reserved(min_time..max_time, space)
      # Visit branching chains
      leaves.each do |l|
        parents = l.parents.collect
          .select{|p| map.include? p.id and map[p.id].space == 0}
        for p in parents
          place_chain(map[p.id], map, l.time)
        end
      end
    end

    def self.mark_reserved(time_range, space)
      for day in time_range
        @_reserved[day].push(space)
      end
    end

    def self.find_free_space(time_range)
      reserved = []
      for day in time_range
          reserved += @_reserved[day]
      end
      space = 1
      while reserved.include? space do
        space += 1
      end
      space
    end

    # Takes most left subtree branch of commits
    # which don't have space mark yet.
    #
    # @param [GraphCommit] the commit object.
    # @param [Hash<String,GraphCommit>] map of commits
    #
    # @return [Array<GraphCommit>] list of branch commits
    def self.take_left_leaves(commit, map)
      leaves = []
      leaves.push(commit)  if commit.space == 0
      while true
        parent = commit.parents.collect
          .select{|p| map.include? p.id and map[p.id].space == 0}
        if parent.count == 0 then
          return leaves
        else
          commit = map[parent.first.id]
          leaves.push(commit)
        end
      end
    end


    def initialize(commit)
      @_commit = commit
      @time = -1
      @space = 0
    end

    def method_missing(m, *args, &block)
      @_commit.send(m, *args, &block)
    end

    def to_graph_hash
      h = {}
      h[:parents] = self.parents.collect do |p|
        [p.id,0,0]
      end
      h[:author]  = Gitlab::Encode.utf8(author.name)
      h[:time]    = time
      h[:space]   = space
      h[:refs]    = refs.collect{|r|r.name}.join(" ") unless refs.nil?
      h[:id]      = sha
      h[:date]    = date
      h[:message] = escape_once(Gitlab::Encode.utf8(message))
      h[:login]   = author.email
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
  end
end
