FactoryGirl.define do
  sequence :title, aliases: [:content] do
    FFaker::Lorem.sentence
  end

  sequence :file_name do
    FFaker::Internet.user_name
  end

  factory :snippet do
    author
    title
    content
    file_name
  end
end
