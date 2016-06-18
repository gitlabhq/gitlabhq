FactoryGirl.define do
  factory :oauth_application, class: 'Doorkeeper::Application', aliases: [:application] do
    name { FFaker::Name.name }
    uid { FFaker::Name.name }
    redirect_uri { FFaker::Internet.uri('http') }
    owner
    owner_type 'User'
  end
end
