FactoryGirl.define do
  factory :email do
    user
    email do
      FFaker::Internet.email('alias')
    end

    factory :another_email do
      email do
        FFaker::Internet.email('another.alias')
      end
    end
  end
end
