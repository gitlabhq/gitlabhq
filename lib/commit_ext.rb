module CommitExt
  # Cause of encoding rails truncate raise error
  # this method is temporary decision
  def truncated_message(size = 80)
    message.length > size ? (message[0..(size - 1)] + "...") : message
  rescue 
    "-- invalid encoding for commit message"
  end
end
