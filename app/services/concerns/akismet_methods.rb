# frozen_string_literal: true

module AkismetMethods
  def spammable_owner
    @user ||= User.find(spammable_owner_id)
  end

  def spammable_owner_id
    @owner_id ||=
      if spammable.respond_to?(:author_id)
        spammable.author_id
      elsif spammable.respond_to?(:creator_id)
        spammable.creator_id
      end
  end

  def akismet
    @akismet ||= AkismetService.new(
      spammable_owner.name,
      spammable_owner.email,
      spammable.spammable_text,
      options
    )
  end
end
