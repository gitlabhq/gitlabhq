# frozen_string_literal: true

module QA
  module Service
    module DockerRun
      class SamlIdp < Base
        include Runtime::Fixtures
        include Support::API

        def initialize(gitlab_host, group, users = nil)
          @image = 'jamedjo/test-saml-idp'
          @name = 'saml-idp-server'
          @gitlab_host = gitlab_host
          @group = group
          @users = users
          super()
        end

        delegate :logger, to: Runtime::Logger

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

        def register!
          command = <<~CMD.tr("\n", ' ')
            docker run -d --rm
            --network #{network}
            --name #{@name}
            --env SIMPLESAMLPHP_SP_ENTITY_ID=#{@gitlab_host}/groups/#{@group}
            --env SIMPLESAMLPHP_SP_ASSERTION_CONSUMER_SERVICE=#{@gitlab_host}/groups/#{@group}/-/saml/callback
            --publish 8080:8080
            --publish 8443:8443
          CMD

          command << " --volume #{authsources}:/var/www/simplesamlphp/config/authsources.php" if @users
          command << " #{@image}"

          shell command

          logger.debug("Waiting for SAML IDP to start...")
          Support::Retrier.retry_until(
            max_attempts: 3,
            sleep_interval: 2,
            retry_on_exception: true,
            message: "Waiting for SAML IDP to start"
          ) do
            logger.debug("Pinging SAML IDP service")
            # Endpoint will return 403 for unauthenticated request once it is up
            get("http://#{host_name}:8080").code == 403
          end
        rescue StandardError => e
          # Remove container on failure because it isn't using a unique name
          remove!
          raise e
        end

        private

        AUTHSOURCES_FILENAME = 'simplesamlphp_authsources.php'

        # Creates an authsources file at `qa/qa/fixtures/saml/simplesamlphp_authsources.php`
        # from a template at `qa/qa/fixtures/saml/simplesamlphp_authsources.php.erb` with group sync permitted by
        # inserting the value of `@group` as the groups attribute
        # See: https://docs.gitlab.com/ee/user/group/saml_sso/group_sync.html#configure-saml-group-sync
        def authsources
          config_path = if ENV['CI_PROJECT_PATH']
                          Runtime::Logger.info("Current working directory: #{Dir.pwd}")
                          File.join("#{Dir.pwd}/rspec", AUTHSOURCES_FILENAME)
                        else
                          Runtime::Path.fixture('saml', AUTHSOURCES_FILENAME)
                        end

          config = ERB.new(read_fixture('saml', "#{AUTHSOURCES_FILENAME}.erb")).result(binding)
          ::File.write(config_path, config)
          config_path.gsub("/home/gitlab/qa", "/builds/gitlab-org/gitlab/qa")
        end
      end
    end
  end
end
