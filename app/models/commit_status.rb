# == Schema Information
#
# Table name: ci_builds
#
#  id                 :integer          not null, primary key
#  project_id         :integer
#  status             :string(255)
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
#  name               :string(255)
#  deploy             :boolean          default(FALSE)
#  options            :text
#  allow_failure      :boolean          default(FALSE), not null
#  stage              :string(255)
#  trigger_request_id :integer
#  stage_idx          :integer
#  tag                :boolean
#  ref                :string(255)
#  user_id            :integer
#  type               :string(255)
#  target_url         :string(255)
#  description        :string(255)
#  artifacts_file     :text
#

class CommitStatus < ActiveRecord::Base
  self.table_name = 'ci_builds'

  belongs_to :commit, class_name: 'Ci::Commit'
  belongs_to :user

  validates :commit, presence: true
  validates :status, inclusion: { in: %w(pending running failed success canceled) }

  validates_presence_of :name

  alias_attribute :author, :user

  scope :running, -> { where(status: 'running') }
  scope :pending, -> { where(status: 'pending') }
  scope :success, -> { where(status: 'success') }
  scope :failed, -> { where(status: 'failed')  }
  scope :running_or_pending, -> { where(status: [:running, :pending]) }
  scope :finished, -> { where(status: [:success, :failed, :canceled]) }
  scope :latest, -> { where(id: unscope(:select).select('max(id)').group(:name, :ref)) }
  scope :ordered, -> { order(:ref, :stage_idx, :name) }
  scope :for_ref, ->(ref) { where(ref: ref) }

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

    after_transition pending: :running do |build, transition|
      build.update_attributes started_at: Time.now
    end

    after_transition any => [:success, :failed, :canceled] do |build, transition|
      build.update_attributes finished_at: Time.now
    end

    state :pending, value: 'pending'
    state :running, value: 'running'
    state :failed, value: 'failed'
    state :success, value: 'success'
    state :canceled, value: 'canceled'
  end

  delegate :sha, :short_sha, :gl_project,
           to: :commit, prefix: false

  # TODO: this should be removed with all references
  def before_sha
    Gitlab::Git::BLANK_SHA
  end

  def started?
    !pending? && !canceled? && started_at
  end

  def active?
    running? || pending?
  end

  def complete?
    canceled? || success? || failed?
  end

  def duration
    if started_at && finished_at
      finished_at - started_at
    elsif started_at
      Time.now - started_at
    end
  end

  def cancel_url
    nil
  end

  def retry_url
    nil
  end

  def show_warning?
    false
  end

  def download_url
    nil
  end
end
