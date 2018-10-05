# frozen_string_literal: true

require_relative '../gitlab/popen' unless defined?(Gitlab::Popen)

module Quality
  class KubernetesClient
    attr_reader :namespace

    def initialize(namespace: ENV['KUBE_NAMESPACE'])
      @namespace = namespace
    end

    def cleanup(release_name:)
      command = ['kubectl']
      command << %(-n "#{namespace}" get ingress,svc,pdb,hpa,deploy,statefulset,job,pod,secret,configmap,pvc,secret,clusterrole,clusterrolebinding,role,rolebinding,sa 2>&1)
      command << '|' << %(grep "#{release_name}")
      command << '|' << "awk '{print $1}'"
      command << '|' << %(xargs kubectl -n "#{namespace}" delete)
      command << '||' << 'true'

      run_command(command)
    end

    private

    def run_command(command)
      puts "Running command: `#{command.join(' ')}`" # rubocop:disable Rails/Output

      Gitlab::Popen.popen_with_detail(command)
    end
  end
end
