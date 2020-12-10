# frozen_string_literal: true

class Vulnerabilities::FindingEntity < Grape::Entity
  include RequestAwareEntity
  include VulnerabilitiesHelper

  expose :id, :report_type, :name, :severity, :confidence
  expose :scanner, using: Vulnerabilities::ScannerEntity
  expose :identifiers, using: Vulnerabilities::IdentifierEntity
  expose :project_fingerprint
  expose :create_jira_issue_url do |occurrence|
    create_jira_issue_url_for(occurrence)
  end
  expose :create_vulnerability_feedback_issue_path do |occurrence|
    create_vulnerability_feedback_issue_path(occurrence.project)
  end
  expose :create_vulnerability_feedback_merge_request_path do |occurrence|
    create_vulnerability_feedback_merge_request_path(occurrence.project)
  end
  expose :create_vulnerability_feedback_dismissal_path do |occurrence|
    create_vulnerability_feedback_dismissal_path(occurrence.project)
  end

  expose :project, using: ::ProjectEntity
  expose :dismissal_feedback, using: Vulnerabilities::FeedbackEntity
  expose :issue_feedback, using: Vulnerabilities::FeedbackEntity
  expose :merge_request_feedback, using: Vulnerabilities::FeedbackEntity

  expose :metadata, merge: true, if: ->(occurrence, _) { occurrence.raw_metadata } do
    expose :description
    expose :links
    expose :location
    expose :remediations
    expose :solution
    expose(:evidence) { |model, _| model.evidence[:summary] }
    expose(:request, using: Vulnerabilities::RequestEntity) { |model, _| model.evidence[:request] }
    expose(:response, using: Vulnerabilities::ResponseEntity) { |model, _| model.evidence[:response] }
    expose(:evidence_source) { |model, _| model.evidence[:source] }
    expose(:supporting_messages) { |model, _| model.evidence[:supporting_messages]}
    expose(:assets) { |model, _| model.assets }
  end

  expose :state
  expose :scan

  expose :blob_path do |occurrence|
    occurrence.present.blob_path
  end

  alias_method :occurrence, :object

  def current_user
    return request.current_user if request.respond_to?(:current_user)
  end
end

Vulnerabilities::FindingEntity.include_if_ee('::EE::ProjectsHelper')
