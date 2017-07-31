class ProjectAccessRequest < ActiveRecord::Base
  belongs_to :project
  belongs_to :user

  def notifiable?(type, opts = {})
    NotificationRecipientService.notifiable?(user, type, notifiable_options.merge(opts))
  end

  def notifiable_options
    {}
  end

  # Make it look like polymorphic Member during refactor
  alias_attribute :source, :project

  def source_id
    project_id
  end

  def real_source_type
    'Project'
  end
end
