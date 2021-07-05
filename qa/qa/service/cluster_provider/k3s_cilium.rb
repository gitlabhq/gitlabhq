# frozen_string_literal: true

module QA
  module Service
    module ClusterProvider
      class K3sCilium < K3s
        def setup
          @k3s = Service::DockerRun::K3s.new.tap do |k3s|
            k3s.remove!
            k3s.cni_enabled = true
            k3s.register!

            shell "kubectl config set-cluster k3s --server https://#{k3s.host_name}:6443 --insecure-skip-tls-verify"
            shell 'kubectl config set-credentials default --username=node --password=some-secret'
            shell 'kubectl config set-context k3s --cluster=k3s --user=default'
            shell 'kubectl config use-context k3s'

            wait_for_server(k3s.host_name) do
              shell 'kubectl version'
              # install local storage
              shell 'kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml'

              # patch local storage
              shell %(kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}')
              shell 'kubectl create -f https://raw.githubusercontent.com/cilium/cilium/v1.8/install/kubernetes/quick-install.yaml'

              wait_for_namespaces do
                wait_for_cilium
                wait_for_coredns do
                  shell 'kubectl create -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-0.31.0/deploy/static/provider/cloud/deploy.yaml'
                  wait_for_ingress
                end
              end
            end
          end
        end

        private

        def wait_for_cilium
          QA::Runtime::Logger.info 'Waiting for Cilium pod to be initialized'

          60.times do
            if service_available?('kubectl get pods --all-namespaces -l k8s-app=cilium --no-headers=true | grep -o "cilium-.*1/1"')
              return yield if block_given?

              return true
            end

            sleep 1
            QA::Runtime::Logger.info '.'
          end

          raise 'Cilium pod has not initialized correctly'
        end

        def wait_for_coredns
          QA::Runtime::Logger.info 'Waiting for CoreDNS pod to be initialized'

          60.times do
            if service_available?('kubectl get pods --all-namespaces --no-headers=true | grep -o "coredns.*1/1"')
              return yield if block_given?

              return true
            end

            sleep 1
            QA::Runtime::Logger.info '.'
          end

          raise 'CoreDNS pod has not been initialized correctly'
        end

        def wait_for_ingress
          QA::Runtime::Logger.info 'Waiting for Ingress controller pod to be initialized'

          60.times do
            if service_available?('kubectl get pods --all-namespaces -l app.kubernetes.io/component=controller | grep -o "ingress-nginx-controller.*1/1"')
              return yield if block_given?

              return true
            end

            sleep 1
            QA::Runtime::Logger.info '.'
          end

          raise 'Ingress pod has not been initialized correctly'
        end
      end
    end
  end
end
