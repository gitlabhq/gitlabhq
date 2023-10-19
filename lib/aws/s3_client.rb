# frozen_string_literal: true

module Aws
  class S3Client
    def initialize(access_key_id, secret_access_key, aws_region)
      credentials = Aws::Credentials.new(access_key_id, secret_access_key)
      @s3_client = Aws::S3::Client.new(region: aws_region, credentials: credentials)
    end

    def upload_object(key, bucket, body, content_type = 'application/json')
      @s3_client.put_object(key: key, bucket: bucket, body: body, content_type: content_type)
    end
  end
end
