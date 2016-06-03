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

class CommitStatus < ActiveRecord::Base
  include Statuseable

  self.table_name = 'ci_builds'

  belongs_to :project, class_name: '::Project', foreign_key: :gl_project_id
  belongs_to :commit, class_name: 'Ci::Commit', touch: true
  belongs_to :user

  validates :commit, presence: true

  validates_presence_of :name

  alias_attribute :author, :user

  scope :latest, -> { where(id: unscope(:select).select('max(id)').group(:name, :commit_id)) }
  scope :ordered, -> { order(:ref, :stage_idx, :name) }
  scope :ignored, -> { where(allow_failure: true, status: [:failed, :canceled]) }

  state_machine :status, initial: :pending do
    event :run do
      transition pending: :running
    end

    event :drop do
      transition [:pending, :running] => :failed
    end

    event :success do
      transition [:pending, :running] => :success
    end

    event :cancel do
      transition [:pending, :running] => :canceled
    end

    after_transition pending: :running do |commit_status|
      commit_status.update_attributes started_at: Time.now
    end

    after_transition any => [:success, :failed, :canceled] do |commit_status|
      commit_status.update_attributes finished_at: Time.now
    end

    after_transition [:pending, :running] => :success do |commit_status|
      MergeRequests::MergeWhenBuildSucceedsService.new(commit_status.commit.project, nil).trigger(commit_status)
    end
  end

  delegate :sha, :short_sha, to: :commit

  def before_sha
    commit.before_sha || Gitlab::Git::BLANK_SHA
  end

  def self.stages
    order_by = 'max(stage_idx)'
    group('stage').order(order_by).pluck(:stage, order_by).map(&:first).compact
  end

  def self.stages_status
    all.stages.inject({}) do |h, stage|
      h[stage] = all.where(stage: stage).status
      h
    end
  end

  def ignored?
    allow_failure? && (failed? || canceled?)
  end

  def duration
    duration =
      if started_at && finished_at
        finished_at - started_at
      elsif started_at
        Time.now - started_at
      end
    duration
  end

  def stuck?
    false
  end
end
