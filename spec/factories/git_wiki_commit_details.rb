# frozen_string_literal: true

FactoryBot.define do
  factory :git_wiki_commit_details, class: 'Gitlab::Git::Wiki::CommitDetails' do
    skip_create

    transient do
      author { association(:user) }
    end

    sequence(:message) { |n| "Commit message #{n}" }

    initialize_with { new(author.id, author.username, author.name, author.email, message) }
  end
end
