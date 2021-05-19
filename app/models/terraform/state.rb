# frozen_string_literal: true

module Terraform
  class State < ApplicationRecord
    include UsageStatistics

    HEX_REGEXP = %r{\A\h+\z}.freeze
    UUID_LENGTH = 32

    belongs_to :project
    belongs_to :locked_by_user, class_name: 'User'

    has_many :versions,
      class_name: 'Terraform::StateVersion',
      foreign_key: :terraform_state_id,
      inverse_of: :terraform_state

    has_one :latest_version, -> { ordered_by_version_desc },
      class_name: 'Terraform::StateVersion',
      foreign_key: :terraform_state_id,
      inverse_of: :terraform_state

    scope :versioning_not_enabled, -> { where(versioning_enabled: false) }
    scope :ordered_by_name, -> { order(:name) }
    scope :with_name, -> (name) { where(name: name) }

    validates :name, presence: true, uniqueness: { scope: :project_id }
    validates :project_id, presence: true
    validates :uuid, presence: true, uniqueness: true, length: { is: UUID_LENGTH },
              format: { with: HEX_REGEXP, message: 'only allows hex characters' }

    before_destroy :ensure_state_is_unlocked

    default_value_for(:uuid, allows_nil: false) { SecureRandom.hex(UUID_LENGTH / 2) }

    def latest_file
      latest_version&.file
    end

    def locked?
      self.lock_xid.present?
    end

    def update_file!(data, version:, build:)
      # This check is required to maintain backwards compatibility with
      # states that were created prior to versioning being supported.
      # This can be removed in 14.0 when support for these states is dropped.
      # See https://gitlab.com/gitlab-org/gitlab/-/issues/258960
      if versioning_enabled?
        create_new_version!(data: data, version: version, build: build)
      else
        migrate_legacy_version!(data: data, version: version, build: build)
      end
    end

    private

    ##
    # If a Terraform state was created before versioning support was
    # introduced, it will have a single version record whose file
    # uses a legacy naming scheme in object storage. To update
    # these states and versions to use the new behaviour, we must do
    # the following when creating the next version:
    #
    #  * Read the current, non-versioned file from the old location.
    #  * Update the :versioning_enabled flag, which determines the
    #    naming scheme
    #  * Resave the existing file with the updated name and location,
    #    using a version number one prior to the new version
    #  * Create the new version as normal
    #
    # This migration only needs to happen once for each state, from
    # then on the state will behave as if it was always versioned.
    #
    # The code can be removed in the next major version (14.0), after
    # which any states that haven't been migrated will need to be
    # recreated: https://gitlab.com/gitlab-org/gitlab/-/issues/258960
    def migrate_legacy_version!(data:, version:, build:)
      current_file = latest_version.file.read
      current_version = parse_serial(current_file) || version - 1

      update!(versioning_enabled: true)

      reload_latest_version.update!(version: current_version, file: CarrierWaveStringFile.new(current_file))
      create_new_version!(data: data, version: version, build: build)
    end

    def create_new_version!(data:, version:, build:)
      new_version = versions.build(version: version, created_by_user: locked_by_user, build: build)
      new_version.assign_attributes(file: data)
      new_version.save!
    end

    def ensure_state_is_unlocked
      return unless locked?

      errors.add(:base, s_("Terraform|You cannot remove the State file because it's locked. Unlock the State file first before removing it."))
      throw :abort # rubocop:disable Cop/BanCatchThrow
    end

    def parse_serial(file)
      Gitlab::Json.parse(file)["serial"]
    rescue JSON::ParserError
    end
  end
end

Terraform::State.prepend_mod
