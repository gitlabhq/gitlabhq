module NewIssuable
  attr_reader :issuable, :user

  def objects_found?(issuable_id, user_id)
    set_user(user_id)
    set_issuable(issuable_id)

    user && issuable
  end

  # rubocop:disable Cop/ModuleWithInstanceVariables
  def set_user(user_id)
    @user = User.find_by(id: user_id)

    log_error(User, user_id) unless @user
  end

  # rubocop:disable Cop/ModuleWithInstanceVariables
  def set_issuable(issuable_id)
    @issuable = issuable_class.find_by(id: issuable_id)

    log_error(issuable_class, issuable_id) unless @issuable
  end

  def log_error(record_class, record_id)
    Rails.logger.error("#{self.class}: couldn't find #{record_class} with ID=#{record_id}, skipping job")
  end
end
