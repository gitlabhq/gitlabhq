FactoryBot.define do
  factory :gitaly_commit_author, class: Gitaly::CommitAuthor do
    skip_create

    name { generate(:name) }
    email { generate(:email) }
    date { Google::Protobuf::Timestamp.new(seconds: Time.now.to_i) }
  end
end
