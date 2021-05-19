# frozen_string_literal: true

module IncidentManagement
  class ProjectIncidentManagementSetting < ApplicationRecord
    include Gitlab::Utils::StrongMemoize

    belongs_to :project

    validate :issue_template_exists, if: :create_issue?

    before_validation :ensure_pagerduty_token

    attr_encrypted :pagerduty_token,
      mode: :per_attribute_iv,
      key: ::Settings.attr_encrypted_db_key_base_32,
      algorithm: 'aes-256-gcm',
      encode: false, # No need to encode for binary column https://github.com/attr-encrypted/attr_encrypted#the-encode-encode_iv-encode_salt-and-default_encoding-options
      encode_iv: false

    def available_issue_templates
      Gitlab::Template::IssueTemplate.all(project)
    end

    def issue_template_content
      strong_memoize(:issue_template_content) do
        issue_template&.content if issue_template_key.present?
      end
    end

    private

    def issue_template_exists
      return unless issue_template_key.present?

      errors.add(:issue_template_key, 'not found') unless issue_template
    end

    def issue_template
      Gitlab::Template::IssueTemplate.find(issue_template_key, project)
    rescue Gitlab::Template::Finders::RepoTemplateFinder::FileNotFoundError
    end

    def ensure_pagerduty_token
      return unless pagerduty_active

      self.pagerduty_token ||= generate_pagerduty_token
    end

    def generate_pagerduty_token
      SecureRandom.hex
    end
  end
end

IncidentManagement::ProjectIncidentManagementSetting.prepend_mod_with('IncidentManagement::ProjectIncidentManagementSetting')
