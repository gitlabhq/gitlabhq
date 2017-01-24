FactoryGirl.define do
  factory :chat_name, class: ChatName do
    user factory: :user
    service factory: :service

    team_id 'T0001'
    team_domain 'Awesome Team'

    sequence :chat_id do |n|
      "U#{n}"
    end
    sequence :chat_name do |n|
      "user#{n}"
    end
  end
end
