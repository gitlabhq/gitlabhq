# frozen_string_literal: true

FactoryBot.define do
  factory :project_member, parent: :member, class: 'ProjectMember' do
    source { association(:project) }
    maintainer
  end
end
