FactoryGirl.define do
  factory :wiki_directory do
    slug '/path_up_to/dir'
    initialize_with { new(slug) }
  end
end
