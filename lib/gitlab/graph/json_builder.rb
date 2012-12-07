require "grit"

module Gitlab
  module Graph
    class JsonBuilder
      attr_accessor :days, :commits, :ref_cache, :repo

      def self.max_count
        @max_count ||= 650
      end

      def initialize project
        @project = project
        @repo = project.repo
        @ref_cache = {}

        @commits = collect_commits
        @days = index_commits
      end
      
      def to_json(*args)
        {
          days: @days.compact.map { |d| [d.day, d.strftime("%b")] },
          commits: @commits.map(&:to_graph_hash)
        }.to_json(*args)
      end
    
    protected

      # Get commits from repository
      #
      def collect_commits
        @commits = Grit::Commit.find_all(repo, nil, {max_count: self.class.max_count}).dup

        # Decorate with app/models/commit.rb
        @commits.map! { |commit| ::Commit.new(commit) }

        # Decorate with lib/gitlab/graph/commit.rb
        @commits.map! { |commit| Gitlab::Graph::Commit.new(commit) }

        # add refs to each commit
        @commits.each { |commit| commit.add_refs(ref_cache, repo) }

        @commits
      end

      # Method is adding time and space on the
      # list of commits. As well as returns date list
      # corelated with time set on commits.
      #
      # @param [Array<Graph::Commit>] comits to index
      #
      # @return [Array<TimeDate>] list of commit dates corelated with time on commits
      def index_commits
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
      # @param [Graph::Commit] the commit object.
      # @param [Hash<String,Graph::Commit>] map of commits
      def place_chain(commit, map, parent_time = nil)
        leaves = take_left_leaves(commit, map)
        if leaves.empty?
          return
        end
        space = find_free_space(leaves.last.time..leaves.first.time)
        leaves.each{|l| l.space = space}
        # and mark it as reserved
        min_time = leaves.last.time
        parents = leaves.last.parents.collect
        parents.each do |p|
          if map.include? p.id
            parent = map[p.id]
            if parent.time < min_time
              min_time = parent.time
            end
          end
        end
        if parent_time.nil?
          max_time = leaves.first.time
        else
          max_time = parent_time - 1
        end
        mark_reserved(min_time..max_time, space)

        # Visit branching chains
        leaves.each do |l|
          parents = l.parents.collect.select{|p| map.include? p.id and map[p.id].space == 0}
          for p in parents
            place_chain(map[p.id], map, l.time)
          end
        end
      end

      def mark_reserved(time_range, space)
        for day in time_range
          @_reserved[day].push(space)
        end
      end

      def find_free_space(time_range)
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
      # @param [Graph::Commit] the commit object.
      # @param [Hash<String,Graph::Commit>] map of commits
      #
      # @return [Array<Graph::Commit>] list of branch commits
      def take_left_leaves(commit, map)
        leaves = []
        leaves.push(commit) if commit.space.zero?

        while true
          parent = commit.parents.collect.select do |p|
            map.include? p.id and map[p.id].space == 0
          end

          return leaves if parent.count.zero?

          commit = map[parent.first.id]
          leaves.push(commit)
        end
      end
    end
  end
end
