# frozen_string_literal: true

module Clusters
  class Project < ActiveRecord::Base
    self.table_name = 'cluster_projects'

    belongs_to :cluster, class_name: 'Clusters::Cluster'
    belongs_to :project, class_name: '::Project'

    attr_encrypted :encrypted_service_account_token,
        mode: :per_attribute_iv,
        key: Settings.attr_encrypted_db_key_base_truncated,
        algorithm: 'aes-256-cbc'

    def default_namespace
      slug.gsub(/[^-a-z0-9]/, '-').gsub(/^-+/, '')
    end

    private

    def slug
      "#{project.path}-#{project.id}".downcase
    end
  end
end
