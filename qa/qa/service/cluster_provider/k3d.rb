# frozen_string_literal: true

module QA
  module Service
    module ClusterProvider
      class K3d < Base
        def validate_dependencies
          find_executable('k3d') || raise("You must first install `k3d` executable to run these tests.")
          Runtime::Env.require_admin_access_token!
          Runtime::ApplicationSettings.set_application_settings(allow_local_requests_from_web_hooks_and_services: true)
        end

        def set_credentials(admin_user)
        end

        def setup
          shell "k3d create --workers 1 --name #{cluster_name} --wait 0"

          @old_kubeconfig = ENV['KUBECONFIG']
          ENV['KUBECONFIG'] = fetch_kubeconfig
          raise "Could not fetch kubeconfig" unless ENV['KUBECONFIG']

          install_local_storage
        end

        def teardown
          ENV['KUBECONFIG'] = @old_kubeconfig
          shell "k3d delete --name #{cluster_name}"
          Runtime::ApplicationSettings.set_application_settings(allow_local_requests_from_web_hooks_and_services: false)
        end

        # Fetch "real" certificate
        # See https://github.com/rancher/k3s/issues/27
        def filter_credentials(credentials)
          kubeconfig = YAML.load_file(ENV['KUBECONFIG'])
          ca_certificate = kubeconfig.dig('clusters', 0, 'cluster', 'certificate-authority-data')

          credentials.merge('data' => credentials['data'].merge('ca.crt' => ca_certificate))
        end

        private

        def retry_until(max_attempts: 10, wait: 1)
          max_attempts.times do
            result = yield
            return result if result

            sleep wait
          end

          raise "Retried #{max_attempts} times. Aborting"
        end

        def fetch_kubeconfig
          retry_until do
            config = `k3d get-kubeconfig --name #{cluster_name}`.chomp
            config if config =~ /kubeconfig.yaml/
          end
        end

        def install_local_storage
          shell('kubectl apply -f -', stdin_data: local_storage_config)
        end

        # See https://github.com/rancher/k3d/issues/67
        def local_storage_config
          <<~YAML
            ---
            apiVersion: v1
            kind: ServiceAccount
            metadata:
              name: storage-provisioner
              namespace: kube-system
            ---
            apiVersion: rbac.authorization.k8s.io/v1
            kind: ClusterRoleBinding
            metadata:
              name: storage-provisioner
            roleRef:
              apiGroup: rbac.authorization.k8s.io
              kind: ClusterRole
              name: system:persistent-volume-provisioner
            subjects:
              - kind: ServiceAccount
                name: storage-provisioner
                namespace: kube-system
            ---
            apiVersion: v1
            kind: Pod
            metadata:
              name: storage-provisioner
              namespace: kube-system
            spec:
              serviceAccountName: storage-provisioner
              tolerations:
              - effect: NoExecute
                key: node.kubernetes.io/not-ready
                operator: Exists
                tolerationSeconds: 300
              - effect: NoExecute
                key: node.kubernetes.io/unreachable
                operator: Exists
                tolerationSeconds: 300
              hostNetwork: true
              containers:
              - name: storage-provisioner
                image: gcr.io/k8s-minikube/storage-provisioner:v1.8.1
                command: ["/storage-provisioner"]
                imagePullPolicy: IfNotPresent
                volumeMounts:
                - mountPath: /tmp
                  name: tmp
              volumes:
              - name: tmp
                hostPath:
                  path: /tmp
                  type: Directory
            ---
            kind: StorageClass
            apiVersion: storage.k8s.io/v1
            metadata:
              name: standard
              namespace: kube-system
              annotations:
                storageclass.kubernetes.io/is-default-class: "true"
              labels:
                addonmanager.kubernetes.io/mode: EnsureExists
            provisioner: k8s.io/minikube-hostpath
          YAML
        end
      end
    end
  end
end
