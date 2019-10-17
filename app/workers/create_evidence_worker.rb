# frozen_string_literal: true

class CreateEvidenceWorker
  include ApplicationWorker

  def perform(release_id)
    release = Release.find_by_id(release_id)
    return unless release

    Evidence.create!(release: release)
  end
end
