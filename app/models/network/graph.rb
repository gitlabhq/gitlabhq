# frozen_string_literal: true

module Network
  class Graph
    attr_reader :days, :commits, :map, :notes, :repo

    def self.max_count
      @max_count ||= 650
    end

    def initialize(project, ref, commit, filter_ref)
      @project = project
      @ref = ref
      @commit = commit
      @filter_ref = filter_ref
      @repo = project.repository

      @commits = collect_commits
      @days = index_commits
      @notes = collect_notes
    end

    protected

    def collect_notes
      h = Hash.new(0)

      @project
        .notes
        .where(noteable_type: 'Commit')
        .group('notes.commit_id')
        .select('notes.commit_id, count(notes.id) as note_count')
        .each do |item|
          h[item.commit_id] = item.note_count.to_i
        end

      h
    end

    # Get commits from repository
    #
    def collect_commits
      # https://gitlab.com/gitlab-org/gitlab-foss/issues/58013
      Gitlab::GitalyClient.allow_n_plus_1_calls do
        find_commits(count_to_display_commit_in_center).map do |commit|
          # Decorate with app/model/network/commit.rb
          Network::Commit.new(commit)
        end
      end
    end

    # Method is adding time and space on the
    # list of commits. As well as returns date list
    # correlated with time set on commits.
    #
    # @return [Array<TimeDate>] list of commit dates correlated with time on commits
    def index_commits
      days = []
      @map = {}
      @reserved = {}

      @commits.each_with_index do |c, i|
        c.time = i
        days[i] = c.committed_date
        @map[c.id] = c
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
      offset = -1
      skip = 0
      while offset == -1
        tmp_commits = find_commits(skip)
        if tmp_commits.present?
          index = tmp_commits.index do |c|
            c.id == @commit.id
          end

          if index
            # Find the target commit
            offset = index + skip
          else
            skip += self.class.max_count
          end
        else
          # Can't find the target commit in the repo.
          offset = 0
        end
      end

      if self.class.max_count / 2 < offset
        # get max index that commit is displayed in the center.
        offset - self.class.max_count / 2
      else
        0
      end
    end

    def find_commits(skip = 0)
      opts = {
        max_count: self.class.max_count,
        skip: skip,
        order: :date
      }

      opts[:ref] = @commit.id if @filter_ref

      Gitlab::Git::Commit.find_all(@repo.raw_repository, opts)
    end

    def commits_sort_by_ref
      @commits.sort do |a, b|
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
      commit.ref_names(@repo).include?(@ref)
    end

    def find_free_parent_spaces(commit)
      spaces = []

      commit.parents(@map).each do |parent|
        range = commit.time..parent.time

        space = if commit.space >= parent.space
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
      if overlap?(range, space_default)
        find_free_space(range, space_step, space_base, space_default)
      else
        space_default
      end
    end

    def overlap?(range, overlap_space)
      range.each do |i|
        if i != range.first &&
            i != range.last &&
            @commits[i].spaces.include?(overlap_space)

          return true
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

      time_range = leaves.first.time..leaves.last.time
      space_base = get_space_base(leaves)
      space = find_free_space(time_range, 2, space_base)
      leaves.each do |l|
        l.spaces << space
      end

      # and mark it as reserved
      min_time =
        if parent_time.nil?
          leaves.first.time
        else
          parent_time + 1
        end

      max_time = leaves.last.time
      leaves.last.parents(@map).each do |parent|
        if max_time < parent.time
          max_time = parent.time
        end
      end
      mark_reserved(min_time..max_time, space)

      # Visit branching chains
      leaves.each do |l|
        parents = l.parents(@map).select {|p| p.space == 0}
        parents.each do |p|
          place_chain(p, l.time)
        end
      end
    end

    def get_space_base(leaves)
      space_base = 1
      parents = leaves.last.parents(@map)
      if parents.present?
        if parents.first.space > 0
          space_base = parents.first.space
        end
      end

      space_base
    end

    def mark_reserved(time_range, space)
      time_range.each do |day|
        @reserved[day].push(space)
      end
    end

    def find_free_space(time_range, space_step, space_base = 1, space_default = nil)
      space_default ||= space_base

      reserved = []
      time_range.each do |day|
        reserved.push(*@reserved[day])
      end
      reserved.uniq!

      space = space_default
      while reserved.include?(space)
        space += space_step
        if space < space_base
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
      leaves.push(commit) if commit.space == 0

      loop do
        return leaves if commit.parents(@map).count == 0

        commit = commit.parents(@map).first

        return leaves unless commit.space == 0

        leaves.push(commit)
      end
    end
  end
end
