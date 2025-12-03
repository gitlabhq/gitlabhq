# frozen_string_literal: true

FactoryBot.define do
  factory :user_saved_view, class: 'WorkItems::SavedViews::UserSavedView' do
    namespace { association(:group) }
    user { association(:user) }
    saved_view { association(:saved_view) }
  end
end
