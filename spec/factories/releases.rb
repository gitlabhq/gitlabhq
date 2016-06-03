# == Schema Information
#
# Table name: releases
#
#  id          :integer          not null, primary key
#  tag         :string(255)
#  description :text
#  project_id  :integer
#  created_at  :datetime
#  updated_at  :datetime
#

FactoryGirl.define do
  factory :release do
    tag "v1.1.0"
    description "Awesome release"
    project
  end
end
