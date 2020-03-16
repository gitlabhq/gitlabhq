# frozen_string_literal: true

FactoryBot.define do
  factory :project_export_job do
    project
    jid { SecureRandom.hex(8) }
  end
end
