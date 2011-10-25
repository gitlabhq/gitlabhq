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
end
