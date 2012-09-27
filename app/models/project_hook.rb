class ProjectHook < WebHook
  belongs_to :project
end

# == Schema Information
#
# Table name: web_hooks
#
#  id         :integer         not null, primary key
#  url        :string(255)
#  project_id :integer
#  created_at :datetime        not null
#  updated_at :datetime        not null
#  type       :string(255)     default("ProjectHook")
#
