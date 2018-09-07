# frozen_string_literal: true

module Ci
  class Stage < ActiveRecord::Base
    extend Gitlab::Ci::Model
    include Importable
    include HasStatus
    include Gitlab::OptimisticLocking

    enum status: HasStatus::STATUSES_ENUM

    belongs_to :project
    belongs_to :pipeline

    has_many :statuses, class_name: 'CommitStatus', foreign_key: :stage_id
    has_many :builds, foreign_key: :stage_id

    with_options unless: :importing? do
      validates :project, presence: true
      validates :pipeline, presence: true
      validates :name, presence: true
      validates :position, presence: true
    end

    after_initialize do
      self.status = DEFAULT_STATUS if self.status.nil?
    end

    before_validation unless: :importing? do
      next if position.present?

      self.position = statuses.select(:stage_idx)
        .where('stage_idx IS NOT NULL')
        .group(:stage_idx)
        .order('COUNT(*) DESC')
        .first&.stage_idx.to_i
    end

    state_machine :status, initial: :created do
      event :enqueue do
        transition created: :pending
        transition [:success, :failed, :canceled, :skipped] => :running
      end

      event :schedule do
        transition [:created, :skipped] => :scheduled
      end

      event :run do
        transition any - [:running] => :running
      end

      event :skip do
        transition any - [:skipped] => :skipped
      end

      event :drop do
        transition any - [:failed] => :failed
      end

      event :succeed do
        transition any - [:success] => :success
      end

      event :cancel do
        transition any - [:canceled] => :canceled
      end

      event :block do
        transition any - [:manual] => :manual
      end
    end

    def update_status
      retry_optimistic_lock(self) do
        case statuses.latest.status
        when 'created' then nil
        when 'scheduled' then schedule
        when 'pending' then enqueue
        when 'running' then run
        when 'success' then succeed
        when 'failed' then drop
        when 'canceled' then cancel
        when 'manual' then block
        when 'skipped', nil then skip
        else
          raise HasStatus::UnknownStatusError,
                "Unknown status `#{statuses.latest.status}`"
        end
      end
    end

    def groups
      @groups ||= Ci::Group.fabricate(self)
    end

    def has_warnings?
      number_of_warnings.positive?
    end

    def number_of_warnings
      BatchLoader.for(id).batch(default_value: 0) do |stage_ids, loader|
        ::Ci::Build.where(stage_id: stage_ids)
          .latest
          .failed_but_allowed
          .group(:stage_id)
          .count
          .each { |id, amount| loader.call(id, amount) }
      end
    end

    def detailed_status(current_user)
      Gitlab::Ci::Status::Stage::Factory
        .new(self, current_user)
        .fabricate!
    end
  end
end
