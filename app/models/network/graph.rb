require "grit"

module Network
  class Graph
    attr_reader :days, :commits, :map

    def self.max_count
      @max_count ||= 650
    end

    def initialize project, ref, commit
      @project = project
      @ref = ref
      @commit = commit
      @repo = project.repo

      @commits = collect_commits
      @days = index_commits
    end

    protected

    # Get commits from repository
    #
    def collect_commits
      refs_cache = build_refs_cache

      Grit::Commit.find_all(
        @repo,
        nil,
        {
          date_order: true,
          max_count: self.class.max_count,
          skip: count_to_display_commit_in_center
        }
      )
      .map do |commit|
          # Decorate with app/model/network/commit.rb
          Network::Commit.new(commit, refs_cache[commit.id])
      end
    end

    # Method is adding time and space on the
    # list of commits. As well as returns date list
    # corelated with time set on commits.
    #
    # @return [Array<TimeDate>] list of commit dates corelated with time on commits
    def index_commits
      days = []
      @map = {}

      @commits.reverse.each_with_index do |c,i|
        c.time = i
        days[i] = c.committed_date
        @map[c.id] = c
      end

      @reserved = {}
      days.each_index do |i|
        @reserved[i] = []
      end

      commits_sort_by_ref.each do |commit|
        place_chain(commit)
      end

      # find parent spaces for not overlap lines
      @commits.each do |c|
        c.parent_spaces.concat(find_free_parent_spaces(c))
      end

      days
    end

    # Skip count that the target commit is displayed in center.
    def count_to_display_commit_in_center
      commit_index = Grit::Commit.find_all(@repo, nil, {date_order: true}).index do |c|
        c.id == @commit.id
      end

      if commit_index && (self.class.max_count / 2 < commit_index) then
        # get max index that commit is displayed in the center.
        commit_index - self.class.max_count / 2
      else
        0
      end
    end

    def commits_sort_by_ref
      @commits.sort do |a,b|
        if include_ref?(a)
          -1
        elsif include_ref?(b)
          1
        else
          b.committed_date <=> a.committed_date
        end
      end
    end

    def include_ref?(commit)
      heads = commit.refs.select do |ref|
        ref.is_a?(Grit::Head) or ref.is_a?(Grit::Remote) or ref.is_a?(Grit::Tag)
      end

      heads.map! do |head|
        head.name
      end

      heads.include?(@ref)
    end

    def find_free_parent_spaces(commit)
      spaces = []

      commit.parents(@map).each do |parent|
        range = if commit.time < parent.time then
                  commit.time..parent.time
                else
                  parent.time..commit.time
                end

        space = if commit.space >= parent.space then
                  find_free_parent_space(range, parent.space, -1, commit.space)
                else
                  find_free_parent_space(range, commit.space, -1, parent.space)
                end

        mark_reserved(range, space)
        spaces << space
      end

      spaces
    end

    def find_free_parent_space(range, space_base, space_step, space_default)
      if is_overlap?(range, space_default) then
        find_free_space(range, space_step, space_base, space_default)
      else
        space_default
      end
    end

    def is_overlap?(range, overlap_space)
      range.each do |i|
        if i != range.first &&
          i != range.last &&
          @commits[reversed_index(i)].spaces.include?(overlap_space) then

          return true;
        end
      end

      false
    end

    # Add space mark on commit and its parents
    #
    # @param [::Commit] the commit object.
    def place_chain(commit, parent_time = nil)
      leaves = take_left_leaves(commit)
      if leaves.empty?
        return
      end

      time_range = leaves.last.time..leaves.first.time
      space_base = get_space_base(leaves)
      space = find_free_space(time_range, 2, space_base)
      leaves.each do |l|
        l.spaces << space
        # Also add space to parent
        l.parents(@map).each do |parent|
          if parent.space > 0
            parent.spaces << space
          end
        end
      end

      # and mark it as reserved
      min_time = leaves.last.time
      leaves.last.parents(@map).each do |parent|
        if parent.time < min_time
          min_time = parent.time
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
        parents = l.parents(@map).select{|p| p.space.zero?}
        for p in parents
          place_chain(p, l.time)
        end
      end
    end

    def get_space_base(leaves)
      space_base = 1
      parents = leaves.last.parents(@map)
      if parents.size > 0
        if parents.first.space > 0
          space_base = parents.first.space
        end
      end
      space_base
    end

    def mark_reserved(time_range, space)
      for day in time_range
        @reserved[day].push(space)
      end
    end

    def find_free_space(time_range, space_step, space_base = 1, space_default = nil)
      space_default ||= space_base

      reserved = []
      for day in time_range
        reserved += @reserved[day]
      end
      reserved.uniq!

      space = space_default
      while reserved.include?(space) do
        space += space_step
        if space < space_base then
          space_step *= -1
          space = space_base + space_step
        end
      end

      space
    end

    # Takes most left subtree branch of commits
    # which don't have space mark yet.
    #
    # @param [::Commit] the commit object.
    #
    # @return [Array<Network::Commit>] list of branch commits
    def take_left_leaves(raw_commit)
      commit = @map[raw_commit.id]
      leaves = []
      leaves.push(commit) if commit.space.zero?

      while true
        return leaves if commit.parents(@map).count.zero?

        commit = commit.parents(@map).first

        return leaves unless commit.space.zero?

        leaves.push(commit)
      end
    end

    def build_refs_cache
      refs_cache = {}
      @repo.refs.each do |ref|
        refs_cache[ref.commit.id] = [] unless refs_cache.include?(ref.commit.id)
        refs_cache[ref.commit.id] << ref
      end
      refs_cache
    end

    def reversed_index(index)
      -index - 1
    end
  end
end
