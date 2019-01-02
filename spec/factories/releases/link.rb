FactoryBot.define do
  factory :release_link, class: ::Releases::Link do
    release
    name "release-18.04.dmg"
    url 'https://my-external-hosting.example.com/scrambled-url/app.zip'
  end
end
