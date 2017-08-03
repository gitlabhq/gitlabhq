FactoryGirl.define do
  factory :gitlab_license, class: "Gitlab::License" do
    skip_create

    starts_at { Date.today - 1.month }
    expires_at { Date.today + 11.months }
    notify_users_at { |l| l.expires_at }
    notify_admins_at { |l| l.expires_at }

    licensee do
      { "Name" => generate(:name) }
    end

    restrictions do
      {
        add_ons: {
          'GitLab_FileLocks' => 1,
          'GitLab_Auditor_User' => 1
        },
        plan: plan
      }
    end

    transient do
      plan License::STARTER_PLAN
    end

    trait :trial do
      restrictions do
        { trial: true }
      end
    end
  end

  factory :license do
    transient do
      plan nil
    end

    data { build(:gitlab_license, plan: plan).export }
  end

  factory :trial_license, class: License do
    data { build(:gitlab_license, :trial).export }
  end
end
