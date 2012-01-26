require "iconv"

class Commit

  attr_accessor :commit
  attr_accessor :head
  attr_accessor :refs

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
    iconv = Iconv.new("UTF-8//IGNORE", "UTF-8")
    iconv.iconv(message + ' ')[0..-2]
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

  def prev_commit
    parents.first
  end
end
