# frozen_string_literal: true

module QA
  module Service
    module ClusterProvider
      class Base
        include Service::Shellout

        attr_reader :rbac

        def initialize(rbac:)
          @rbac = rbac
        end

        def cluster_name
          @cluster_name ||= "qa-cluster-#{Time.now.utc.strftime('%Y%m%d%H%M%S')}-#{SecureRandom.hex(4)}"
        end

        def set_credentials(admin_user)
          raise NotImplementedError
        end

        def validate_dependencies
          raise NotImplementedError
        end

        def setup
          raise NotImplementedError
        end

        def teardown
          raise NotImplementedError
        end

        def filter_credentials(credentials)
          credentials
        end
      end
    end
  end
end
