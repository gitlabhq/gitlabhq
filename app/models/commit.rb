class Commit
  include ActiveModel::Conversion
  include Gitlab::Encode
  include StaticModel
  extend ActiveModel::Naming

  attr_accessor :commit, :head, :refs

  delegate  :message, :authored_date, :committed_date, :parents, :sha,
            :date, :committer, :author, :message, :diffs, :tree, :id,
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

      first = project.commit(to.try(:strip))
      last = project.commit(from.try(:strip))

      if first && last
        commits = [first, last].sort_by(&:created_at)
        younger = commits.first
        older = commits.last

        result[:same] = (younger.id == older.id)
        result[:commits] = project.repo.commits_between(younger.id, older.id).map {|c| Commit.new(c)}
        result[:diffs] = project.repo.diff(younger.id, older.id) rescue []
        result[:commit] = Commit.new(older)
      end

      result
    end
  end

  def initialize(raw_commit, head = nil)
    @commit = raw_commit
    @head = head
  end

  def short_id(length = 10)
    id.to_s[0..length]
  end

  def safe_message
    utf8 message
  end

  def created_at
    committed_date
  end

  def author_email
    author.email
  end

  def author_name
    utf8 author.name
  end

  # Was this commit committed by a different person than the original author?
  def different_committer?
    author_name != committer_name || author_email != committer_email
  end

  def committer_name
    utf8 committer.name
  end

  def committer_email
    committer.email
  end

  def prev_commit
    parents.try :first
  end

  def prev_commit_id
    prev_commit.try :id
  end

  def parents_count
    parents && parents.count || 0
  end
end
