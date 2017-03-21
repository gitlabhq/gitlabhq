FactoryGirl.define do
  factory :chat_team, class: ChatTeam do
    sequence :team_id do |n|
      "abcdefghijklm#{n}"
    end

    namespace factory: :group
  end
end
