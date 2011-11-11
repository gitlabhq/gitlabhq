module CommitExt
  def safe_message
    message.encode("UTF-8",
                   :invalid => :replace,
                   :undef => :replace,
                   :universal_newline => true,
                   :replace => "")
  rescue
    "-- invalid encoding for commit message"
  end

  def safe_message_no_signoff
    if safe_message.include? 'Signed-off-by:'
      safe_message[0..safe_message.index('Signed-off-by:')-2]
    else
      safe_message
    end
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
