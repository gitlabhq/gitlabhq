# == Schema Information
#
# Table name: label_links
#
#  id          :integer          not null, primary key
#  label_id    :integer
#  target_id   :integer
#  target_type :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#

FactoryGirl.define do
  factory :label_link do
    label
    target factory: :issue
  end
end
