module NewIssuable
  attr_reader :issuable, :user

  def ensure_objects_found(issuable_id, user_id)
    @issuable = issuable_class.find_by(id: issuable_id)
    unless @issuable
      log_error(issuable_class, issuable_id)
      return false
    end

    @user = User.find_by(id: user_id)
    unless @user
      log_error(User, user_id)
      return false
    end

    true
  end

  def log_error(record_class, record_id)
    Rails.logger.error("#{self.class}: couldn't find #{record_class} with ID=#{record_id}, skipping job")
  end
end
