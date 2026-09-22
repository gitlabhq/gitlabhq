# frozen_string_literal: true

require 'carrierwave/orm/activerecord'

class ProjectImportData < ApplicationRecord
  include Gitlab::EncryptedAttribute

  prepend_mod_with('ProjectImportData') # rubocop: disable Cop/InjectEnterpriseEditionModule

  # Timeout strategy can only be changed via API, currently only with GitHub and BitBucket Server
  OPTIMISTIC_TIMEOUT = "optimistic"
  PESSIMISTIC_TIMEOUT = "pessimistic"
  TIMEOUT_STRATEGIES = [OPTIMISTIC_TIMEOUT, PESSIMISTIC_TIMEOUT].freeze

  belongs_to :project, inverse_of: :import_data
  attr_encrypted :credentials,
    key: :db_key_base,
    marshal: true,
    encode: true,
    mode: :per_attribute_iv_and_salt,
    insecure_mode: true,
    algorithm: 'aes-256-cbc'

  # NOTE
  # We are serializing a project as `data` in an "unsafe" way here
  # because the credentials are necessary for a successful import.
  # This is safe because the serialization is only going between rails
  # and the database, never to any end users.
  serialize :data, coder: Serializers::UnsafeJson # rubocop:disable Cop/ActiveRecordSerialize

  validates :project, presence: true

  before_validation :symbolize_credentials

  def symbolize_credentials
    # bang doesn't work here - attr_encrypted makes it not to work
    self.credentials = self.credentials.deep_symbolize_keys unless self.credentials.blank?
  end

  def merge_data(hash)
    self.data = data.to_h.merge(hash) unless hash.empty?
  end

  def merge_credentials(hash)
    self.credentials = credentials.to_h.merge(hash) unless hash.empty?
  end

  # User contribution mapping is the safe default: contributions point at
  # placeholder users rather than resolving to arbitrary target users. Only
  # Bitbucket Server can opt out via feature flag while it remains in beta.
  #
  # The accessor deliberately does not read the stored `data` blob because
  # ProjectImportState deletes it on cancel/fail; an attacker who cancels
  # their own import mid-flight could otherwise downgrade running workers to
  # the legacy user-resolution path and spoof author IDs on imported records.
  # See gitlab-org/gitlab#628379.
  def user_mapping_enabled?
    return false if bitbucket_server_user_mapping_disabled?

    true
  end

  private

  def bitbucket_server_user_mapping_disabled?
    return false unless project&.import_type == 'bitbucket_server'

    Feature.disabled?(:bitbucket_server_user_mapping, project.creator)
  end
end
