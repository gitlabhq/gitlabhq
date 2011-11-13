module CommitExt
  attr_accessor :head
  attr_accessor :refs

  def safe_message
    message.encode("UTF-8",
                   :invalid => :replace,
                   :undef => :replace,
                   :universal_newline => true,
                   :replace => "")
  rescue
    "-- invalid encoding for commit message"
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
