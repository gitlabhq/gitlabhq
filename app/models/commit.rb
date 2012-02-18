class Commit
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :commit
  attr_accessor :head
  attr_accessor :refs

  delegate :message,
    :authored_date,
    :committed_date,
    :parents,
    :sha,
    :date,
    :committer,
    :author,
    :message,
    :diffs,
    :tree,
    :id,
    :to => :commit

  def persisted?
    false
  end

  def initialize(raw_commit, head = nil)
    @commit = raw_commit
    @head = head
  end

  def safe_message
    message
  end

  def created_at
    committed_date
  end

  def author_email
    author.email
  end

  def author_name
    author.name.force_encoding("UTF-8")
  end

  def committer_name
    committer.name
  end

  def committer_email
    committer.email
  end

  def prev_commit
    parents.first
  end
end
