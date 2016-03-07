FactoryGirl.define do
  factory :gitlab_license, class: "Gitlab::License" do
    starts_at { Date.today - 1.month }
    expires_at { Date.today + 11.months }
    licensee do
      { "Name" => FFaker::Name.name }
    end
    notify_users_at   { |l| l.expires_at }
    notify_admins_at  { |l| l.expires_at }
  end

  factory :license do
    data { build(:gitlab_license).export }
  end
end
