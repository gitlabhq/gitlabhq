module Gcp
  class Cluster < ActiveRecord::Base
    extend Gitlab::Gcp::Model
    include Presentable

    belongs_to :project, inverse_of: :cluster
    belongs_to :user
    belongs_to :service

    scope :enabled, -> { where(enabled: true) }
    scope :disabled, -> { where(enabled: false) }

    default_value_for :gcp_cluster_zone, 'us-central1-a'
    default_value_for :gcp_cluster_size, 3
    default_value_for :gcp_machine_type, 'n1-standard-4'

    attr_encrypted :password,
      mode: :per_attribute_iv,
      key: Gitlab::Application.secrets.db_key_base,
      algorithm: 'aes-256-cbc'

    attr_encrypted :kubernetes_token,
      mode: :per_attribute_iv,
      key: Gitlab::Application.secrets.db_key_base,
      algorithm: 'aes-256-cbc'

    attr_encrypted :gcp_token,
      mode: :per_attribute_iv,
      key: Gitlab::Application.secrets.db_key_base,
      algorithm: 'aes-256-cbc'

    validates :gcp_project_id,
      length: 1..63,
      format: {
        with: Gitlab::Regex.kubernetes_namespace_regex,
        message: Gitlab::Regex.kubernetes_namespace_regex_message
      }

    validates :gcp_cluster_name,
      length: 1..63,
      format: {
        with: Gitlab::Regex.kubernetes_namespace_regex,
        message: Gitlab::Regex.kubernetes_namespace_regex_message
      }

    validates :gcp_cluster_zone, presence: true

    validates :gcp_cluster_size,
      presence: true,
      numericality: {
        only_integer: true,
        greater_than: 0
      }

    validates :project_namespace,
      allow_blank: true,
      length: 1..63,
      format: {
        with: Gitlab::Regex.kubernetes_namespace_regex,
        message: Gitlab::Regex.kubernetes_namespace_regex_message
      }

    # if we do not do status transition we prevent change
    validate :restrict_modification, on: :update, unless: :status_changed?

    state_machine :status, initial: :scheduled do
      state :scheduled, value: 1
      state :creating, value: 2
      state :created, value: 3
      state :errored, value: 4

      event :make_creating do
        transition any - [:creating] => :creating
      end

      event :make_created do
        transition any - [:created] => :created
      end

      event :make_errored do
        transition any - [:errored] => :errored
      end

      before_transition any => [:errored, :created] do |cluster|
        cluster.gcp_token = nil
        cluster.gcp_operation_id = nil
      end

      before_transition any => [:errored] do |cluster, transition|
        status_reason = transition.args.first
        cluster.status_reason = status_reason if status_reason
      end
    end

    def project_namespace_placeholder
      "#{project.path}-#{project.id}"
    end

    def on_creation?
      scheduled? || creating?
    end

    def api_url
      'https://' + endpoint if endpoint
    end

    def restrict_modification
      if on_creation?
        errors.add(:base, "cannot modify during creation")
        return false
      end

      true
    end
  end
end
