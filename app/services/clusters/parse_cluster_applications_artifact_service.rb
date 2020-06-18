# frozen_string_literal: true

module Clusters
  class ParseClusterApplicationsArtifactService < ::BaseService
    include Gitlab::Utils::StrongMemoize

    MAX_ACCEPTABLE_ARTIFACT_SIZE = 5.kilobytes
    RELEASE_NAMES = %w[prometheus].freeze

    def initialize(job, current_user)
      @job = job

      super(job.project, current_user)
    end

    def execute(artifact)
      return success unless Feature.enabled?(:cluster_applications_artifact, project)

      raise ArgumentError, 'Artifact is not cluster_applications file type' unless artifact&.cluster_applications?

      return error(too_big_error_message, :bad_request) unless artifact.file.size < MAX_ACCEPTABLE_ARTIFACT_SIZE
      return error(no_deployment_message, :bad_request) unless job.deployment
      return error(no_deployment_cluster_message, :bad_request) unless cluster

      parse!(artifact)

      success
    rescue Gitlab::Kubernetes::Helm::Parsers::ListV2::ParserError, ActiveRecord::RecordInvalid => error
      Gitlab::ErrorTracking.track_exception(error, job_id: artifact.job_id)
      error(error.message, :bad_request)
    end

    private

    attr_reader :job

    def cluster
      strong_memoize(:cluster) do
        deployment_cluster = job.deployment&.cluster

        deployment_cluster if Ability.allowed?(current_user, :admin_cluster, deployment_cluster)
      end
    end

    def parse!(artifact)
      releases = []

      artifact.each_blob do |blob|
        releases.concat(Gitlab::Kubernetes::Helm::Parsers::ListV2.new(blob).releases)
      end

      update_cluster_application_statuses!(releases)
    end

    def update_cluster_application_statuses!(releases)
      release_by_name = releases.index_by { |release| release['Name'] }

      Clusters::Cluster.transaction do
        RELEASE_NAMES.each do |release_name|
          application_class = Clusters::Cluster::APPLICATIONS[release_name]
          application = cluster.find_or_build_application(application_class)

          release = release_by_name[release_name]

          if release
            case release['Status']
            when 'DEPLOYED'
              application.make_externally_installed!
            when 'FAILED'
              application.make_errored!(s_('ClusterIntegration|Helm release failed to install'))
            end
          else
            # missing, so by definition, we consider this uninstalled
            application.make_externally_uninstalled! if application.persisted?
          end
        end
      end
    end

    def too_big_error_message
      human_size = ActiveSupport::NumberHelper.number_to_human_size(MAX_ACCEPTABLE_ARTIFACT_SIZE)

      s_('ClusterIntegration|Cluster_applications artifact too big. Maximum allowable size: %{human_size}') % { human_size: human_size }
    end

    def no_deployment_message
      s_('ClusterIntegration|No deployment found for this job')
    end

    def no_deployment_cluster_message
      s_('ClusterIntegration|No deployment cluster found for this job')
    end
  end
end
