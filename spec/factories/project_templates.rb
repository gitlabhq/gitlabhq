# == Schema Information
#
# Table name: project_templates
#
#  id          :integer          not null, primary key
#  name        :string(100)
#  description :text
#  upload      :string(400)
#  state       :integer          default(0)
#  created_at  :datetime
#  updated_at  :datetime
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :project_template do
    id 1
    name "MyString"
    path "MyString"
    description "MyText"
  end
end
