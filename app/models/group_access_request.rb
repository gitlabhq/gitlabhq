class GroupAccessRequest < ActiveRecord::Base
  belongs_to :group
  belongs_to :user
  
  def notifiable?(type, opts = {})
    NotificationRecipientService.notifiable?(user, type, notifiable_options.merge(opts))
  end

  def notifiable_options
    {}
  end

  # Make it look like polymorphic Member during refactor
  alias_attribute :source, :group

  def source_id
    group_id
  end

  def real_source_type
    'Group'
  end
end
