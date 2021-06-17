# frozen_string_literal: true

class ContainerExpirationPolicy < ApplicationRecord
  include Schedulable
  include UsageStatistics
  include EachBatch

  POLICY_PARAMS = %w[
    older_than
    keep_n
    name_regex
    name_regex_keep
  ].freeze

  belongs_to :project, inverse_of: :container_expiration_policy

  delegate :container_repositories, to: :project

  validates :project, presence: true
  validates :enabled, inclusion: { in: [true, false] }
  validates :cadence, presence: true, inclusion: { in: ->(_) { self.cadence_options.stringify_keys } }
  validates :older_than, inclusion: { in: ->(_) { self.older_than_options.stringify_keys } }, allow_nil: true
  validates :keep_n, inclusion: { in: ->(_) { self.keep_n_options.keys } }, allow_nil: true
  validates :name_regex, presence: true, if: :enabled?
  validates :name_regex, untrusted_regexp: true, if: :enabled?
  validates :name_regex_keep, untrusted_regexp: true, if: :enabled?

  scope :active, -> { where(enabled: true) }
  scope :preloaded, -> { preload(project: [:route]) }

  def self.with_container_repositories
    where(
      'EXISTS (?)',
      ContainerRepository.select(1)
                         .where(
                           'container_repositories.project_id = container_expiration_policies.project_id'
                         )
    )
  end

  def self.without_container_repositories
    where.not(
      'EXISTS(?)',
      ContainerRepository.select(1)
                         .where(
                           'container_repositories.project_id = container_expiration_policies.project_id'
                         )
    )
  end

  def self.keep_n_options
    {
      1 => _('%{tags} tag per image name') % { tags: 1 },
      5 => _('%{tags} tags per image name') % { tags: 5 },
      10 => _('%{tags} tags per image name') % { tags: 10 },
      25 => _('%{tags} tags per image name') % { tags: 25 },
      50 => _('%{tags} tags per image name') % { tags: 50 },
      100 => _('%{tags} tags per image name') % { tags: 100 }
    }
  end

  def self.cadence_options
    {
      '1d': _('Every day'),
      '7d': _('Every week'),
      '14d': _('Every two weeks'),
      '1month': _('Every month'),
      '3month': _('Every three months')
    }
  end

  def self.older_than_options
    {
      '7d': _('%{days} days until tags are automatically removed') % { days: 7 },
      '14d': _('%{days} days until tags are automatically removed') % { days: 14 },
      '30d': _('%{days} days until tags are automatically removed') % { days: 30 },
      '90d': _('%{days} days until tags are automatically removed') % { days: 90 }
    }
  end

  def set_next_run_at
    self.next_run_at = Time.zone.now + ChronicDuration.parse(cadence).seconds
  end

  def disable!
    update_attribute(:enabled, false)
  end

  def policy_params
    attributes.slice(*POLICY_PARAMS)
  end
end
