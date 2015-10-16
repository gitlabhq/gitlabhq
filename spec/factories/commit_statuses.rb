FactoryGirl.define do
  factory :commit_status, class: CommitStatus do
    started_at 'Di 29. Okt 09:51:28 CET 2013'
    finished_at 'Di 29. Okt 09:53:28 CET 2013'
    name 'default'
    status 'success'
    description 'commit status'
    commit factory: :ci_commit

    factory :generic_commit_status, class: GenericCommitStatus do
      name 'generic'
      description 'external commit status'
    end
  end
end
