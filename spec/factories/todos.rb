# == Schema Information
#
# Table name: todos
#
#  id          :integer          not null, primary key
#  user_id     :integer          not null
#  project_id  :integer          not null
#  target_id   :integer
#  target_type :string           not null
#  author_id   :integer
#  action      :integer          not null
#  state       :string           not null
#  created_at  :datetime
#  updated_at  :datetime
#  note_id     :integer
#  commit_id   :string
#

FactoryGirl.define do
  factory :todo do
    project
    author
    user
    target factory: :issue
    action { Todo::ASSIGNED }

    trait :assigned do
      action { Todo::ASSIGNED }
    end

    trait :mentioned do
      action { Todo::MENTIONED }
    end

    trait :on_commit do
      commit_id RepoHelpers.sample_commit.id
      target_type "Commit"
    end
  end
end
