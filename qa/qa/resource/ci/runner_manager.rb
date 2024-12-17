# frozen_string_literal: true

module QA
  module Resource
    module Ci
      class RunnerManager < Base
        attr_accessor :system_xid, :config, :executor_type

        attributes :id,
          :token,
          :token_expires_at,
          :version,
          :revision,
          :platform,
          :architecture,
          :ip_address,
          :runner

        def initialize
          @system_xid = "r_#{SecureRandom.hex(6)}"
          @executor_type = :shell
          @version = nil
          @revision = nil
          @platform = nil
          @architecture = nil
          @ip_address = nil
        end

        def fabricate!
          fabricate_via_api!
        end

        def fabricate_via_api!
          api_post
        end

        def full_path
          "runners/managers?id=#{id}&system_id=#{system_xid}"
        end

        def api_get_path
          "/runners/managers"
        end

        def api_post_path
          "/runners/verify"
        end

        def api_delete_path
          "/runners/managers"
        end

        def api_post_body
          {
            token: runner.token,
            system_id: system_xid,
            version: version, revision: revision, platform: platform, architecture: architecture,
            executor: executor_type, ip_address: ip_address,
            config: config
          }.compact
        end

        def api_delete_body
          {
            token: runner.token,
            system_id: system_xid
          }
        end

        private

        def post_success_response_code
          HTTP_STATUS_OK
        end
      end
    end
  end
end
