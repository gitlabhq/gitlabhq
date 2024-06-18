# frozen_string_literal: true

class JiraConnectSubscription < ApplicationRecord
  belongs_to :installation, class_name: 'JiraConnectInstallation', foreign_key: 'jira_connect_installation_id'
  belongs_to :namespace

  validates :installation, presence: true
  validates :namespace, presence: true, uniqueness: { scope: :jira_connect_installation_id, message: 'has already been added' }

  scope :preload_namespace_route, -> { preload(namespace: :route) }
  scope :for_project, ->(project) { where(namespace_id: project.namespace.self_and_ancestor_ids) }
end
