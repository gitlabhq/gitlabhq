# == Schema Information
#
# Table name: groups
#
#  id         :integer         not null, primary key
#  name       :string(255)     not null
#  code       :string(255)     not null
#  owner_id   :integer         not null
#  created_at :datetime        not null
#  updated_at :datetime        not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :group do
    name "MyString"
    code "MyString"
    owner_id 1
  end
end
