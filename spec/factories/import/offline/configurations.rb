# frozen_string_literal: true

FactoryBot.define do
  factory :import_offline_configuration, class: 'Import::Offline::Configuration', aliases: [:offline_configuration] do
    offline_export { association(:offline_export) if bulk_import.nil? }
    organization
    bucket { 'gitlab-exports' }
    source_hostname { 'https://offline.example.com' }

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

    trait :s3_compatible do
      provider { :s3_compatible }
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

    trait :gcs do
      provider { :gcs }
      object_storage_credentials do
        {
          google_project: 'gitlab-project',
          type: 'service_account',
          project_id: 'gitlab-project',
          private_key: "-----BEGIN PRIVATE KEY-----\nFAKEKEYCONTENTS\n-----END PRIVATE KEY-----\n",
          client_email: 'gcs@gitlab-project.iam.gserviceaccount.com'
        }
      end
    end

    trait :gcs_hmac do
      provider { :gcs_hmac }
      object_storage_credentials do
        {
          google_storage_access_key_id: 'GOOG1EXAMPLEACCESSKEY123',
          google_storage_secret_access_key: 'AbCd+EfGh/IjKlMnOpQrStUvWxYz0123456789K=', # gitleaks:allow
          region: 'us-east1',
          path_style: true
        }
      end
    end

    trait :with_bulk_import do
      bulk_import { association(:bulk_import, :offline) }
    end
  end
end
