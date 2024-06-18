# frozen_string_literal: true

FactoryBot.define do
  factory :project_export_job do
    project
    jid { SecureRandom.hex(8) }

    trait :queued do
      status { ProjectExportJob::STATUS[:queued] }
    end

    trait :started do
      status { ProjectExportJob::STATUS[:started] }
    end

    trait :finished do
      status { ProjectExportJob::STATUS[:finished] }
    end

    trait :failed do
      status { ProjectExportJob::STATUS[:failed] }
    end

    exported_by_admin { user&.can_admin_all_resources? }
  end
end
