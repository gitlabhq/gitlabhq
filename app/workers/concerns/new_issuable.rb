# frozen_string_literal: true

module NewIssuable
  attr_reader :issuable, :user

  def objects_found?(issuable_id, user_id)
    set_user(user_id)
    set_issuable(issuable_id)

    user && issuable
  end

  def set_user(user_id)
    @user = User.find_by_id(user_id) # rubocop:disable Gitlab/ModuleWithInstanceVariables

    log_error(User, user_id) unless @user # rubocop:disable Gitlab/ModuleWithInstanceVariables
  end

  def set_issuable(issuable_id)
    @issuable = issuable_class.find_by_id(issuable_id) # rubocop:disable Gitlab/ModuleWithInstanceVariables

    log_error(issuable_class, issuable_id) unless @issuable # rubocop:disable Gitlab/ModuleWithInstanceVariables
  end

  def log_error(record_class, record_id)
    Gitlab::AppLogger.error("#{self.class}: couldn't find #{record_class} with ID=#{record_id}, skipping job")
  end
end
