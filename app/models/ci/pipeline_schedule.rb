# frozen_string_literal: true

module Ci
  class PipelineSchedule < Ci::ApplicationRecord
    extend ::Gitlab::Utils::Override
    include Importable
    include StripAttribute
    include CronSchedulable
    include Limitable
    include EachBatch
    include BatchNullifyDependentAssociations
    include Gitlab::Utils::StrongMemoize

    VALID_REF_FORMAT_REGEX = %r{\A(#{Gitlab::Git::TAG_REF_PREFIX}|#{Gitlab::Git::BRANCH_REF_PREFIX})[\S]+}

    SORT_ORDERS = {
      id_asc: { order_by: 'id', sort: 'asc' },
      id_desc: { order_by: 'id', sort: 'desc' },
      description_asc: { order_by: 'description', sort: 'asc' },
      description_desc: { order_by: 'description', sort: 'desc' },
      ref_asc: { order_by: 'ref', sort: 'asc' },
      ref_desc: { order_by: 'ref', sort: 'desc' },
      next_run_at_asc: { order_by: 'next_run_at', sort: 'asc' },
      next_run_at_desc: { order_by: 'next_run_at', sort: 'desc' },
      created_at_asc: { order_by: 'created_at', sort: 'asc' },
      created_at_desc: { order_by: 'created_at', sort: 'desc' },
      updated_at_asc: { order_by: 'updated_at', sort: 'asc' },
      updated_at_desc: { order_by: 'updated_at', sort: 'desc' }
    }.freeze

    self.limit_name = 'ci_pipeline_schedules'
    self.limit_scope = :project

    belongs_to :project
    belongs_to :owner, class_name: 'User'
    has_one :last_pipeline, -> { order(id: :desc) }, class_name: 'Ci::Pipeline', inverse_of: :pipeline_schedule
    has_many :pipelines, dependent: :nullify # rubocop:disable Cop/ActiveRecordDependent
    has_many :variables, class_name: 'Ci::PipelineScheduleVariable'

    validates :cron, unless: :importing?, cron: true, presence: { unless: :importing? }
    validates :cron_timezone, cron_timezone: true, presence: { unless: :importing? }
    validates :ref, presence: { unless: :importing? }
    validates :description, presence: true
    validates :variables, nested_attributes_duplicates: true

    strip_attributes! :cron

    scope :active, -> { where(active: true) }
    scope :inactive, -> { where(active: false) }
    scope :preloaded, -> { preload(:owner, project: [:route]) }
    scope :owned_by, ->(user) { where(owner: user) }
    scope :for_project, ->(project_id) { where(project_id: project_id) }

    accepts_nested_attributes_for :variables, allow_destroy: true

    alias_attribute :real_next_run, :next_run_at

    def self.sort_by_attribute(method)
      sort_order = SORT_ORDERS[method]
      raise ArgumentError, "order undefined" unless sort_order

      reorder(sort_order[:order_by] => sort_order[:sort])
    end

    def owned_by?(current_user)
      owner == current_user
    end

    def own!(user)
      update(owner: user)
    end

    def inactive?
      !active?
    end

    def deactivate!
      update_attribute(:active, false)
    end

    def job_variables
      variables&.map(&:to_hash_variable) || []
    end

    override :set_next_run_at

    def set_next_run_at
      self.next_run_at = ::Ci::PipelineSchedules::CalculateNextRunService # rubocop: disable CodeReuse/ServiceClass
                           .new(project)
                           .execute(self, fallback_method: method(:calculate_next_run_at))
    end

    def daily_limit
      project.actual_limits.limit_for(:ci_daily_pipeline_schedule_triggers)
    end

    def ref_for_display
      return unless ref.present?

      ref.gsub(%r{^refs/(heads|tags)/}, '')
    end

    def for_tag?
      return false unless ref.present?

      ref.start_with? 'refs/tags/'
    end

    def worker_cron_expression
      Settings.cron_jobs['pipeline_schedule_worker']['cron']
    end

    # Using destroy instead of before_destroy as we want nullify_dependent_associations_in_batches
    # to run first and not in a transaction block. This prevents timeouts for schedules with numerous pipelines
    def destroy
      nullify_dependent_associations_in_batches

      super
    end

    def expand_short_ref
      return if ref.blank? || VALID_REF_FORMAT_REGEX.match?(ref) || ambiguous_ref?

      # In case the ref doesn't exist default to the initial value
      self.ref = project.repository.expand_ref(ref) || ref
    end

    private

    def ambiguous_ref?
      strong_memoize_with(:ambiguous_ref, ref) do
        project.repository.ambiguous_ref?(ref)
      end
    end
  end
end

Ci::PipelineSchedule.prepend_mod_with('Ci::PipelineSchedule')
