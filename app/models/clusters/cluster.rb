module Clusters
  class Cluster < ActiveRecord::Base
    include Presentable

    belongs_to :user
    belongs_to :service

    enum :platform_type {
      kubernetes: 1
    }

    enum :provider_type {
      user: 0,
      gcp: 1
    }

    has_many :cluster_projects
    has_many :projects, through: :cluster_projects

    has_one :gcp_provider
    has_one :kubernetes_platform

    accepts_nested_attributes_for :gcp_provider
    accepts_nested_attributes_for :kubernetes_platform

    validates :kubernetes_platform, presence: true, if: :kubernetes?
    validates :gcp_provider, presence: true, if: :gcp?
    validate :restrict_modification, on: :update

    delegate :status, to: :provider, allow_nil: true
    delegate :status_reason, to: :provider, allow_nil: true

    def restrict_modification
      if provider&.on_creation?
        errors.add(:base, "cannot modify during creation")
        return false
      end

      true
    end

    def provider
      return gcp_provider if gcp?
    end

    def platform
      return kubernetes_platform if kubernetes?
    end

    def first_project
      return @first_project if defined?(@first_project)

      @first_project = projects.first
    end
  end
end
