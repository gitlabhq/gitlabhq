module Ci
  class CreateJobService < BaseService
    def execute(subject = nil)
      (subject || yield).tap do |subject|
        Ci::EnsureStageService.new(project, current_user)
          .execute(subject)

        subject.save
      end
    end
  end
end
