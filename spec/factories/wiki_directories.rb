FactoryBot.define do
  factory :wiki_directory do
    skip_create

    slug '/path_up_to/dir'
    initialize_with { new(slug) }
  end
end
