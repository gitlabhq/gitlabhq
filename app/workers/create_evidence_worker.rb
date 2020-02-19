# frozen_string_literal: true

class CreateEvidenceWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  feature_category :release_governance
  weight 2

  def perform(release_id)
    release = Release.find_by_id(release_id)
    return unless release

    Evidence.create!(release: release)
  end
end
