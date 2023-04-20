# frozen_string_literal: true

FactoryBot.define do
  factory :search_index, class: 'Search::Index' do
    initialize_with { type.present? ? type.new : Search::Index.new }
    sequence(:path) { |n| "index-path-#{n}" }
    sequence(:bucket_number) { |n| n }
    type { Search::NoteIndex }
  end
end
