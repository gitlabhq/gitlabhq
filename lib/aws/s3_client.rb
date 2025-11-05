# frozen_string_literal: true

module Aws
  class S3Client
    def initialize(access_key_id, secret_access_key, aws_region)
      credentials = Aws::Credentials.new(access_key_id, secret_access_key)
      @s3_client = Aws::S3::Client.new(
        region: aws_region,
        credentials: credentials,
        # Default value is 1, which will send a 1xx, but GitLab rejects all 1xx responses by default
        # So we change this to nil
        http_continue_timeout: nil
      )
    end

    def upload_object(key, bucket, body, content_type = 'application/json')
      @s3_client.put_object(key: key, bucket: bucket, body: body, content_type: content_type)
    end
  end
end
