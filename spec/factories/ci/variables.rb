# == Schema Information
#
# Table name: ci_variables
#
#  id                   :integer          not null, primary key
#  project_id           :integer          not null
#  key                  :string(255)
#  value                :text
#  encrypted_value      :text
#  encrypted_value_salt :string(255)
#  encrypted_value_iv   :string(255)
#  gl_project_id        :integer
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :ci_variable, class: Ci::Variable do
    id 1
    key 'TEST_VARIABLE_1'
    value 'VALUE_1'

    project factory: :empty_project
  end
end
