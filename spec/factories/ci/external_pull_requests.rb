# frozen_string_literal: true

FactoryBot.define do
  factory :external_pull_request, class: 'Ci::ExternalPullRequest' do
    sequence(:pull_request_iid)
    project
    source_branch { 'feature' }
    source_repository { 'the-repository' }
    source_sha { '97de212e80737a608d939f648d959671fb0a0142' }
    target_branch { 'master' }
    target_repository { 'the-repository' }
    target_sha { 'a09386439ca39abe575675ffd4b89ae824fec22f' }
    status { :open }

    trait(:closed) { status { 'closed' } }
  end
end
