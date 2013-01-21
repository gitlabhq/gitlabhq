class Commit
  include ActiveModel::Conversion
  include StaticModel
  extend ActiveModel::Naming

  # Safe amount of files with diffs in one commit to render
  # Used to prevent 500 error on huge commits by suppressing diff
  #
  DIFF_SAFE_SIZE = 100

  attr_accessor :commit, :head, :refs

  delegate  :message, :authored_date, :committed_date, :parents, :sha,
            :date, :committer, :author, :diffs, :tree, :id, :stats,
            :to_patch, to: :commit

  class << self
    def find_or_first(repo, commit_id = nil, root_ref)
      commit = if commit_id
                 repo.commit(commit_id)
               else
                 repo.commits(root_ref).first
               end

      Commit.new(commit) if commit
    end

    def fresh_commits(repo, n = 10)
      commits = repo.heads.map do |h|
        repo.commits(h.name, n).map { |c| Commit.new(c, h) }
      end.flatten.uniq { |c| c.id }

      commits.sort! do |x, y|
        y.committed_date <=> x.committed_date
      end

      commits[0...n]
    end

    def commits_with_refs(repo, n = 20)
      commits = repo.branches.map { |ref| Commit.new(ref.commit, ref) }

      commits.sort! do |x, y|
        y.committed_date <=> x.committed_date
      end

      commits[0..n]
    end

    def commits_since(repo, date)
      commits = repo.heads.map do |h|
        repo.log(h.name, nil, since: date).each { |c| Commit.new(c, h) }
      end.flatten.uniq { |c| c.id }

      commits.sort! do |x, y|
        y.committed_date <=> x.committed_date
      end

      commits
    end

    def commits(repo, ref, path = nil, limit = nil, offset = nil)
      if path
        repo.log(ref, path, max_count: limit, skip: offset)
      elsif limit && offset
        repo.commits(ref, limit, offset)
      else
        repo.commits(ref)
      end.map{ |c| Commit.new(c) }
    end

    def commits_between(repo, from, to)
      repo.commits_between(from, to).map { |c| Commit.new(c) }
    end

    def compare(project, from, to)
      result = {
        commits: [],
        diffs: [],
        commit: nil,
        same: false
      }

      return result unless from && to

      first = project.repository.commit(to.try(:strip))
      last = project.repository.commit(from.try(:strip))

      if first && last
        result[:same] = (first.id == last.id)
        result[:commits] = project.repo.commits_between(last.id, first.id).map {|c| Commit.new(c)}
        result[:diffs] = project.repo.diff(last.id, first.id) rescue []
        result[:commit] = Commit.new(first)
      end

      result
    end
  end

  def initialize(raw_commit, head = nil)
    raise "Nil as raw commit passed" unless raw_commit

    @commit = raw_commit
    @head = head
  end

  def short_id(length = 10)
    id.to_s[0..length]
  end

  def safe_message
    @safe_message ||= message
  end

  def created_at
    committed_date
  end

  def author_email
    author.email
  end

  def author_name
    author.name
  end

  # Was this commit committed by a different person than the original author?
  def different_committer?
    author_name != committer_name || author_email != committer_email
  end

  def committer_name
    committer.name
  end

  def committer_email
    committer.email
  end

  def prev_commit
    @prev_commit ||= if parents.present?
                       Commit.new(parents.first)
                     else
                       nil
                     end
  end

  def prev_commit_id
    prev_commit.try :id
  end

  # Shows the diff between the commit's parent and the commit.
  #
  # Cuts out the header and stats from #to_patch and returns only the diff.
  def to_diff
    # see Grit::Commit#show
    patch = to_patch

    # discard lines before the diff
    lines = patch.split("\n")
    while !lines.first.start_with?("diff --git") do
      lines.shift
    end
    lines.pop if lines.last =~ /^[\d.]+$/ # Git version
    lines.pop if lines.last == "-- "      # end of diff
    lines.join("\n")
  end
end
