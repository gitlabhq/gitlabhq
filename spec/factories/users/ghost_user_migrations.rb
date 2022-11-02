# frozen_string_literal: true

FactoryBot.define do
  factory :ghost_user_migration, class: 'Users::GhostUserMigration' do
    association :user
    initiator_user { association(:user) }
    hard_delete { false }
    consume_after { Time.current }
  end
end
