# frozen_string_literal: true

module QA
  module Service
    module ClusterProvider
      class K3s < Base
        def validate_dependencies
          Runtime::ApplicationSettings.set_application_settings(allow_local_requests_from_web_hooks_and_services: true)
        end

        def setup
          @k3s = Service::DockerRun::K3s.new.tap do |k3s|
            k3s.remove!
            k3s.register!

            shell "kubectl config set-cluster k3s --server https://#{k3s.host_name}:6443 --insecure-skip-tls-verify"
            shell 'kubectl config set-credentials default --username=node --password=some-secret'
            shell 'kubectl config set-context k3s --cluster=k3s --user=default'
            shell 'kubectl config use-context k3s'

            wait_for_server(k3s.host_name) do
              shell 'kubectl version'

              wait_for_namespaces do
                # install local storage
                shell 'kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml'

                # patch local storage
                shell %(kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}')
              end
            end
          end
        end

        def teardown
          Runtime::ApplicationSettings.set_application_settings(allow_local_requests_from_web_hooks_and_services: false)

          @k3s&.remove!
        end

        def set_credentials(admin_user); end

        # Fetch "real" certificate
        # See https://github.com/rancher/k3s/issues/27
        def filter_credentials(credentials)
          kubeconfig = YAML.safe_load(@k3s.kubeconfig)
          ca_certificate = kubeconfig.dig('clusters', 0, 'cluster', 'certificate-authority-data')

          credentials.merge('data' => credentials['data'].merge('ca.crt' => ca_certificate))
        end

        private

        def wait_for_server(host_name)
          print "Waiting for K3s server at `https://#{host_name}:6443` to become available "

          60.times do
            if service_available?('kubectl version')
              return yield if block_given?

              return true
            end

            sleep 1
            print '.'
          end

          raise 'K3s server never came up'
        end

        def wait_for_namespaces
          print 'Waiting for k8s namespaces to populate'

          60.times do
            if service_available?('kubectl get pods --all-namespaces | grep --silent "Running"')
              return yield if block_given?

              return true
            end

            sleep 1
            print '.'
          end

          raise 'K8s namespaces didnt populate correctly'
        end

        def service_available?(command)
          system("#{command} > /dev/null 2>&1")
        end
      end
    end
  end
end
