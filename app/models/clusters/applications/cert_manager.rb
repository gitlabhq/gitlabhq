# frozen_string_literal: true

module Clusters
    module Applications
      class CertManager < ActiveRecord::Base
        VERSION = 'v0.5.0'.freeze
  
        self.table_name = 'clusters_applications_cert_managers'

        include ::Clusters::Concerns::ApplicationCore
        include ::Clusters::Concerns::ApplicationStatus
        include ::Clusters::Concerns::ApplicationVersion
        include ::Clusters::Concerns::ApplicationData
  
        default_value_for :version, VERSION
  
        def ready_status
          [:installed]
        end
  
        def ready?
          ready_status.include?(status_name)
        end
  
        def chart
          'stable/cert-manager'
        end

        def install_command
          Gitlab::AppLogger.info '----- INSTALLING CLUSTER ISSUER-v2 ----'
          begin
            Gitlab::Kubernetes::Helm::InstallCommand.new(
              name: 'certmanager',
              version: VERSION,
              rbac: cluster.platform_kubernetes_rbac?,
              chart: chart,
              files: files.merge!(cluster_issuer_file),
              postinstall: post_install_script
            )
            #res = YAML.load_file(Rails.root.join('config', 'cert_manager', 'cluster_issuer.yaml'))
            #Gitlab::AppLogger.info(res)
            #Gitlab::Kubernetes::ClusterIssuer(res).generate()
          rescue StandardError => e
            Gitlab::AppLogger.info('install_command_eror------------------------------------------------')
            Gitlab::AppLogger.error(e)
            Gitlab::AppLogger.error(e.backtrace.join("\n"))
          rescue Exception => e
            Gitlab::AppLogger.info('install_command_exception--------------------------------------------------')
            Gitlab::AppLogger.error(e)
            Gitlab::AppLogger.error(e.backtrace.join("\n"))
          end    
        end

        def cluster_issuer_resource_definition
          YAML.load_file(Rails.root.join('config', 'cert_manager', 'cluster_issuer.yaml'))
        end

        private

        def post_install_script
          ["/usr/bin/kubectl create -f /data/helm/certmanager/config/cluster_issuer.yaml"]
        end

        def cluster_issuer_file
          {
            'cluster_issuer.yaml': File.read(cluster_issuer_file_path)
          }
        end

        def cluster_issuer_file_path
          "#{Rails.root}/vendor/cert_manager/cluster_issuer.yaml"
        end
      end
    end
  end
  