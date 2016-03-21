# == Schema Information
#
# Table name: forked_project_links
#
#  id                     :integer          not null, primary key
#  forked_to_project_id   :integer          not null
#  forked_from_project_id :integer          not null
#  created_at             :datetime
#  updated_at             :datetime
#

FactoryGirl.define do
  factory :forked_project_link do
    association :forked_to_project, factory: :project
    association :forked_from_project, factory: :project
  end
end
