# frozen_string_literal: true

require_relative '../gitlab/popen' unless defined?(Gitlab::Popen)

module Quality
  class KubernetesClient
    RESOURCE_LIST = 'ingress,svc,pdb,hpa,deploy,statefulset,job,pod,secret,configmap,pvc,secret,clusterrole,clusterrolebinding,role,rolebinding,sa,crd'
    CommandFailedError = Class.new(StandardError)

    attr_reader :namespace

    def initialize(namespace:)
      @namespace = namespace
    end

    def cleanup(release_name:, wait: true)
      delete_by_selector(release_name: release_name, wait: wait)
      delete_by_matching_name(release_name: release_name)
    end

    private

    def delete_by_selector(release_name:, wait:)
      selector = case release_name
                 when String
                   %(-l release="#{release_name}")
                 when Array
                   %(-l 'release in (#{release_name.join(', ')})')
                 else
                   raise ArgumentError, 'release_name must be a string or an array'
                 end

      command = [
        'delete',
        RESOURCE_LIST,
        %(--namespace "#{namespace}"),
        '--now',
        '--ignore-not-found',
        '--include-uninitialized',
        %(--wait=#{wait}),
        selector
      ]

      run_command(command)
    end

    def delete_by_matching_name(release_name:)
      resource_names = raw_resource_names
      command = [
        'delete',
        %(--namespace "#{namespace}")
      ]

      Array(release_name).each do |release|
        resource_names
          .select { |resource_name| resource_name.include?(release) }
          .each { |matching_resource| run_command(command + [matching_resource]) }
      end
    end

    def raw_resource_names
      command = [
        'get',
        RESOURCE_LIST,
        %(--namespace "#{namespace}"),
        '-o custom-columns=NAME:.metadata.name'
      ]
      run_command(command).lines.map(&:strip)
    end

    def run_command(command)
      final_command = ['kubectl', *command].join(' ')
      puts "Running command: `#{final_command}`" # rubocop:disable Rails/Output

      result = Gitlab::Popen.popen_with_detail([final_command])

      if result.status.success?
        result.stdout.chomp.freeze
      else
        raise CommandFailedError, "The `#{final_command}` command failed (status: #{result.status}) with the following error:\n#{result.stderr}"
      end
    end
  end
end
