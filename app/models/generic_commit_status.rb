# == Schema Information
#
# Table name: ci_builds
#
#  id                 :integer          not null, primary key
#  project_id         :integer
#  status             :string
#  finished_at        :datetime
#  trace              :text
#  created_at         :datetime
#  updated_at         :datetime
#  started_at         :datetime
#  runner_id          :integer
#  coverage           :float
#  commit_id          :integer
#  commands           :text
#  job_id             :integer
#  name               :string
#  deploy             :boolean          default(FALSE)
#  options            :text
#  allow_failure      :boolean          default(FALSE), not null
#  stage              :string
#  trigger_request_id :integer
#  stage_idx          :integer
#  tag                :boolean
#  ref                :string
#  user_id            :integer
#  type               :string
#  target_url         :string
#  description        :string
#  artifacts_file     :text
#  gl_project_id      :integer
#  artifacts_metadata :text
#  erased_by_id       :integer
#  erased_at          :datetime
#

class GenericCommitStatus < CommitStatus
  before_validation :set_default_values

  # GitHub compatible API
  alias_attribute :context, :name

  def set_default_values
    self.context ||= 'default'
    self.stage ||= 'external'
  end

  def tags
    [:external]
  end
end
