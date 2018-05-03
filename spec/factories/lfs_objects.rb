include ActionDispatch::TestProcess

FactoryBot.define do
  factory :lfs_object do
    sequence(:oid) { |n| "b68143e6463773b1b6c6fd009a76c32aeec041faff32ba2ed42fd7f708a%05x" % n }
    size 499013
  end

  trait :with_file do
    file do
      tmp_file = Tempfile.new("lfs-binary-file")
      tmp_file.binmode
      tmp_file.write(SecureRandom.random_bytes(256))
      tmp_file.close

      file_sha256 = Digest::SHA256.file(tmp_file.path).hexdigest

      UploadedFile.new(tmp_file.path,
        filename: file_sha256[4..-1],
        content_type: 'application/octet-stream',
        sha256: file_sha256,
        remote_id: nil)
    end

    oid { Digest::SHA256.file(file.path).hexdigest }
    size { File.size(file.path) }
  end

  # The uniqueness constraint means we can't use the correct OID for all LFS
  # objects, so the test needs to decide which (if any) object gets it
  trait :correct_oid do
    oid 'b804383982bb89b00e828e3f44c038cc991d3d1768009fc39ba8e2c081b9fb75'
  end

  trait :object_storage do
    file_store { LfsObjectUploader::Store::REMOTE }
  end
end
