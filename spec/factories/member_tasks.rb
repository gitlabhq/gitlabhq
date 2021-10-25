# frozen_string_literal: true

FactoryBot.define do
  factory :member_task do
    member { association(:group_member, :invited) }
    project { association(:project, namespace: member.source) }
    tasks_to_be_done { [:ci, :code] }
  end
end
