# frozen_string_literal: true

module QA
  module Service
    module Gitlab
      class Instances
        attr_reader :list

        def initialize
          @list = []
        end

        # Default omnibus configuration for a GitLab instance
        # @param cell_url [String] the external url for the GitLab instance
        def omnibus_configuration(cell_url:)
          <<~OMNIBUS
          gitlab_rails['lfs_enabled'] = true;
          gitlab_rails['initial_root_password']= '#{Runtime::Env.admin_password}'
          external_url '#{cell_url}';
          OMNIBUS
        end

        # Sets the gitlab_url values so that gitlab-qa flows work on one of the instances
        # @param instance [DockerRun::GitLab object] the GitLab instance to be used
        def set_gitlab_urls(instance)
          Support::GitlabAddress.define_gitlab_address_attribute!(instance.external_url)
          Runtime::Env.gitlab_url = instance.external_url
          Runtime::Scenario.define(:gitlab_address, instance.external_url)
        end

        # Creates a DockerRun::Gitlab instance and adds to the list of instances
        # @param name [string] the name for the instance
        # @param url [string] the URL for the instance
        # @param external_port [string] the external port
        # @param internal_port [string] the internal port to use instead of default (optional)
        # @param omnibus_config [string] omnibus_configuration to use instead of default (optional)
        # @return [Service::DockerRun::Gitlab] the last created GitLab instance
        def add_gitlab_instance(name:, url:, external_port:, internal_port: '80', omnibus_config: nil)
          cell_url = "http://#{url}/"
          external_url = "http://#{url}:#{external_port}/"
          ports = "#{external_port}:#{internal_port}"
          omnibus_config ||= omnibus_configuration(cell_url: cell_url)
          @list << Service::DockerRun::Gitlab.new(
            image: Runtime::Env.release,
            name: name,
            ports: ports,
            omnibus_config: omnibus_config,
            external_url: external_url).tap do |gitlab|
            gitlab.login
            gitlab.register!
          end

          @list.last
        end

        # Waits for an instance to be healthy
        # @param instance [DockerRun::GitLab object] the GitLab instance to be checked
        def wait_for_instance(instance)
          Support::Waiter.wait_until(max_duration: 900, sleep_interval: 10, raise_on_failure: true) do
            instance.health == "healthy"
          end
        end

        def wait_for_all_instances
          @list.each { |el| wait_for_instance(el) }
        end

        def remove_all_instances
          @list.each(&:remove!)

          @list.clear
        end

        # Remove an instance with a given name
        # @param instance_name [String] the name of the instance that was specified during initialization
        def remove_instance(instance_name)
          index = @list.index { |x| x.name == instance_name }
          instance = @list.slice!(index)
          instance.remove!
        end
      end
    end
  end
end
