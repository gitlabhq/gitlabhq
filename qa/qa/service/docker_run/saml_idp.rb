# frozen_string_literal: true

module QA
  module Service
    module DockerRun
      class SamlIdp < Base
        def initialize(gitlab_host, group)
          @image = 'jamedjo/test-saml-idp'
          @name = 'saml-idp-server'
          @gitlab_host = gitlab_host
          @group = group
          super()
        end

        def idp_base_url
          "https://#{host_name}:8443/simplesaml"
        end

        def idp_sso_url
          "#{idp_base_url}/saml2/idp/SSOService.php"
        end

        def idp_sign_out_url
          "#{idp_base_url}/module.php/core/authenticate.php?as=example-userpass&logout"
        end

        def idp_signed_out_url
          "#{idp_base_url}/logout.php"
        end

        def idp_metadata_url
          "#{idp_base_url}/saml2/idp/metadata.php"
        end

        def idp_issuer
          idp_metadata_url
        end

        def idp_certificate_fingerprint
          QA::Runtime::Env.simple_saml_fingerprint || '119b9e027959cdb7c662cfd075d9e2ef384e445f'
        end

        def host_name
          return 'localhost' unless QA::Runtime::Env.running_in_ci?

          super
        end

        def register!
          command = <<~CMD.tr("\n", ' ')
            docker run -d --rm
            --network #{network}
            --hostname #{host_name}
            --name #{@name}
            --env SIMPLESAMLPHP_SP_ENTITY_ID=#{@gitlab_host}/groups/#{@group}
            --env SIMPLESAMLPHP_SP_ASSERTION_CONSUMER_SERVICE=#{@gitlab_host}/groups/#{@group}/-/saml/callback
            --publish 8080:8080
            --publish 8443:8443
            #{@image}
          CMD

          command.gsub!("--network #{network} ", '') unless QA::Runtime::Env.running_in_ci?

          shell command
        end
      end
    end
  end
end
