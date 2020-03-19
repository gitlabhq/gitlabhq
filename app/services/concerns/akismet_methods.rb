# frozen_string_literal: true

module AkismetMethods
  def target_owner
    @user ||= User.find(target.author_id)
  end

  def akismet
    @akismet ||= Spam::AkismetService.new(
      target_owner.name,
      target_owner.email,
      target.try(:spammable_text) || target&.text,
      options
    )
  end
end
