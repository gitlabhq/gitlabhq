# == Schema Information
#
# Table name: lfs_objects
#
#  id         :integer          not null, primary key
#  oid        :string(255)      not null
#  size       :integer          not null
#  created_at :datetime
#  updated_at :datetime
#  file       :string(255)
#

include ActionDispatch::TestProcess

FactoryGirl.define do
  factory :lfs_object do
    oid "b68143e6463773b1b6c6fd009a76c32aeec041faff32ba2ed42fd7f708a17f80"
    size 499013
  end

  trait :with_file do
    file { fixture_file_upload(Rails.root + "spec/fixtures/dk.png", "`/png") }
  end
end
