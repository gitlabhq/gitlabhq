class Commit
  attr_accessor :commit
  attr_accessor :head

  delegate :message,
    :committed_date,
    :parents,
    :sha,
    :date,
    :author,
    :message,
    :diffs,
    :tree,
    :id,
    :to => :commit

  def initialize(raw_commit, head = nil)
    @commit = raw_commit
    @head = head
  end

  def safe_message
    message.force_encoding(Encoding::UTF_8)
  end

  def created_at
    committed_date
  end

  def author_email
    author.email.force_encoding(Encoding::UTF_8)
  end

  def author_name
    author.name.force_encoding(Encoding::UTF_8)
  end
end
