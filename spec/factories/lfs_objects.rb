# frozen_string_literal: true

FactoryBot.define do
  factory :lfs_object do
    sequence(:oid) { |n| "b68143e6463773b1b6c6fd009a76c32aeec041faff32ba2ed42fd7f708a%05x" % n }
    size { 499013 }
  end

  trait :with_file do
    file { fixture_file_upload("spec/fixtures/dk.png", "`/png") }
  end

  # The uniqueness constraint means we can't use the correct OID for all LFS
  # objects, so the test needs to decide which (if any) object gets it
  trait :correct_oid do
    oid { 'b804383982bb89b00e828e3f44c038cc991d3d1768009fc39ba8e2c081b9fb75' }
    size { 1062 }
  end

  trait :object_storage do
    file_store { LfsObjectUploader::Store::REMOTE }
  end

  trait :with_lfs_object_dot_iso_file do
    with_file
    object_storage
    oid { '91eff75a492a3ed0dfcb544d7f31326bc4014c8551849c192fd1e48d4dd2c897' }
    size { 133 }
  end
end
