module EE
  module Gitlab
    module Rack
      module Attack
        module Request
          extend ::Gitlab::Utils::Override

          override :should_be_skipped?
          def should_be_skipped?
            super || geo?
          end

          def geo?
            ::Gitlab::Geo::JwtRequestDecoder.geo_auth_attempt?(env['HTTP_AUTHORIZATION']) if env['HTTP_AUTHORIZATION']
          end
        end
      end
    end
  end
end
