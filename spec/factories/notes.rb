# == Schema Information
#
# Table name: notes
#
#  id            :integer          not null, primary key
#  note          :text
#  noteable_type :string(255)
#  author_id     :integer
#  created_at    :datetime
#  updated_at    :datetime
#  project_id    :integer
#  attachment    :string(255)
#  line_code     :string(255)
#  commit_id     :string(255)
#  noteable_id   :integer
#  system        :boolean          default(FALSE), not null
#  st_diff       :text
#  updated_by_id :integer
#  is_award      :boolean          default(FALSE), not null
#

require_relative '../support/repo_helpers'

include ActionDispatch::TestProcess

FactoryGirl.define do
  factory :note do
    project
    note "Note"
    author

    factory :note_on_commit,             traits: [:on_commit]
    factory :note_on_commit_diff,        traits: [:on_commit, :on_diff]
    factory :note_on_issue,              traits: [:on_issue], aliases: [:votable_note]
    factory :note_on_merge_request,      traits: [:on_merge_request]
    factory :note_on_merge_request_diff, traits: [:on_merge_request, :on_diff]
    factory :note_on_project_snippet,    traits: [:on_project_snippet]
    factory :system_note,                traits: [:system]
    factory :downvote_note,              traits: [:award, :downvote]
    factory :upvote_note,                traits: [:award, :upvote]

    trait :on_commit do
      project
      commit_id RepoHelpers.sample_commit.id
      noteable_type "Commit"
    end

    trait :on_diff do
      line_code "0_184_184"
    end

    trait :on_merge_request do
      project
      noteable_id 1
      noteable_type "MergeRequest"
    end

    trait :on_issue do
      noteable_id 1
      noteable_type "Issue"
    end

    trait :on_project_snippet do
      noteable_id 1
      noteable_type "Snippet"
    end

    trait :system do
      system true
    end

    trait :award do
      is_award true
    end

    trait :downvote do
      note "thumbsdown"
    end

    trait :upvote do
      note "thumbsup"
    end

    trait :with_attachment do
      attachment { fixture_file_upload(Rails.root + "spec/fixtures/dk.png", "`/png") }
    end
  end
end
