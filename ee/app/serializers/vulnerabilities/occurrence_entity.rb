# frozen_string_literal: true

class Vulnerabilities::OccurrenceEntity < Grape::Entity
  include RequestAwareEntity

  expose :id, :report_type, :name, :severity, :confidence
  expose :scanner, using: Vulnerabilities::ScannerEntity
  expose :identifiers, using: Vulnerabilities::IdentifierEntity
  expose :project_fingerprint
  expose :vulnerability_feedback_url, if: ->(*) { can_admin_vulnerability_feedback? }
  expose :project, using: ::ProjectEntity
  expose :dismissal_feedback, using: VulnerabilityFeedbackEntity
  expose :issue_feedback, using: VulnerabilityFeedbackEntity

  expose :metadata, merge: true, if: ->(occurrence, _) { occurrence.raw_metadata } do
    expose :description
    expose :solution
    expose :location
    expose :links
  end

  alias_method :occurrence, :object

  private

  def vulnerability_feedback_url
    project_vulnerability_feedback_index_url(occurrence.project)
  end

  def can_admin_vulnerability_feedback?
    can?(request.current_user, :admin_vulnerability_feedback, occurrence.project)
  end
end
