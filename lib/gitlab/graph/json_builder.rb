require "grit"

module Gitlab
  module Graph
    class JsonBuilder
      attr_accessor :days, :commits, :ref_cache, :repo

      def self.max_count
        @max_count ||= 650
      end

      def initialize project, ref
        @project = project
        @ref = ref
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
        days, heads, times = [], [], []
        map = {}

        commits.reverse.each_with_index do |c,i|
          c.time = i
          days[i] = c.committed_date
          map[c.id] = c
          heads += c.refs unless c.refs.nil?
          times[i] = c
        end

        heads.select!{|h| h.is_a? Grit::Head or h.is_a? Grit::Remote}
        # sort heads so the master is top and current branches are closer
        heads.sort! do |a,b|
          if a.name == @ref
            -1
          elsif b.name == @ref
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

        # find parent spaces for not overlap lines
        times.each do |c|
          c.parent_spaces.concat(find_free_parent_spaces(c, map, times))
        end

        days
      end

      def find_free_parent_spaces(commit, map, times)
        spaces = []

        commit.parents.each do |p|
          if map.include?(p.id) then
            parent = map[p.id]

            range = if commit.time < parent.time then
                      commit.time..parent.time
                    else
                      parent.time..commit.time
                    end

            space = if commit.space >= parent.space then
                      find_free_parent_space(range, parent.space, 1, commit.space, times)
                    else
                      find_free_parent_space(range, parent.space, -1, parent.space, times)
                    end

            mark_reserved(range, space)
            spaces << space
          end
        end

        spaces
      end

      def find_free_parent_space(range, space_base, space_step, space_default, times)
        if is_overlap?(range, times, space_default) then
          find_free_space(range, space_base, space_step)
        else
          space_default
        end
      end

      def is_overlap?(range, times, overlap_space)
        range.each do |i|
          if i != range.first &&
            i != range.last &&
            times[i].space == overlap_space then

            return true;
          end
        end

        false
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
        # and mark it as reserved
        min_time = leaves.last.time
        max_space = 1
        parents = leaves.last.parents.collect
        parents.each do |p|
          if map.include? p.id
            parent = map[p.id]
            if parent.time < min_time
              min_time = parent.time
            end
            if max_space < parent.space then
              max_space = parent.space
            end
          end
        end
        if parent_time.nil?
          max_time = leaves.first.time
        else
          max_time = parent_time - 1
        end

        time_range = leaves.last.time..leaves.first.time
        space = find_free_space(time_range, max_space, 2)
        leaves.each{|l| l.space = space}

        mark_reserved(min_time..max_time, space)

        # Visit branching chains
        leaves.each do |l|
          parents = l.parents.collect.select{|p| map.include? p.id and map[p.id].space.zero?}
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

      def find_free_space(time_range, space_base, space_step)
        reserved = []
        for day in time_range
          reserved += @_reserved[day]
        end
        reserved.uniq!

        space = space_base
        while reserved.include?(space) do
          space += space_step
          if space <= 0 then
            space_step *= -1
            space = space_base + space_step
          end
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
          return leaves if commit.parents.count.zero?
          return leaves unless map.include? commit.parents.first.id

          commit = map[commit.parents.first.id]

          return leaves unless commit.space.zero?

          leaves.push(commit)
        end
      end
    end
  end
end
