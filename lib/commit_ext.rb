module CommitExt
  attr_accessor :head
  attr_accessor :refs

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
