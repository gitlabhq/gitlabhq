# frozen_string_literal: true

FactoryBot.define do
  factory :import_offline_configuration, class: 'Import::Offline::Configuration', aliases: [:offline_configuration] do
    offline_export
    organization
    bucket { 'gitlab-exports' }

    aws_s3

    trait :aws_s3 do
      provider { :aws }
      object_storage_credentials do
        {
          aws_access_key_id: 'AwsUserAccessKey',
          aws_secret_access_key: 'aws/secret+access/key',
          region: 'us-east-1',
          path_style: false
        }
      end
    end

    trait :minio do
      provider { :minio }
      object_storage_credentials do
        {
          aws_access_key_id: 'minio-user-access-key',
          aws_secret_access_key: 'minio-secret-access-key',
          region: 'gdk',
          endpoint: 'https://minio.example.com',
          path_style: true
        }
      end
    end
  end
end
