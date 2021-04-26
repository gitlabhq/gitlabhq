# frozen_string_literal: true

module Lfs
  # Lfs::PushService pushes the LFS objects associated with a project to a
  # remote URL
  class PushService < BaseService
    include Gitlab::Utils::StrongMemoize

    # Match the canonical LFS client's batch size:
    # https://github.com/git-lfs/git-lfs/blob/master/tq/transfer_queue.go#L19
    BATCH_SIZE = 100

    def execute
      lfs_objects_relation.each_batch(of: BATCH_SIZE) do |objects|
        push_objects!(objects)
      end

      success
    rescue StandardError => err
      Gitlab::ErrorTracking.log_exception(err, extra_context)
      error(err.message)
    end

    private

    def extra_context
      { project_id: project.id, user_id: current_user&.id }.compact
    end

    # Currently we only set repository_type for design repository objects, so
    # push mirroring must send objects with a `nil` repository type - but if the
    # wiki repository uses LFS, its objects will also be sent. This will be
    # addressed by https://gitlab.com/gitlab-org/gitlab/-/issues/250346
    def lfs_objects_relation
      project.lfs_objects_for_repository_types(nil, :project)
    end

    def push_objects!(objects)
      rsp = lfs_client.batch!('upload', objects)
      objects = objects.index_by(&:oid)

      rsp.fetch('objects', []).each do |spec|
        actions = spec['actions']
        object = objects[spec['oid']]

        upload_object!(object, spec) if actions&.key?('upload')
        verify_object!(object, spec) if actions&.key?('verify')
      end
    end

    def upload_object!(object, spec)
      authenticated = spec['authenticated']
      upload = spec.dig('actions', 'upload')

      # The server wants us to upload the object but something is wrong
      unless object && object.size == spec['size'].to_i
        log_error("Couldn't match object #{spec['oid']}/#{spec['size']}")
        return
      end

      lfs_client.upload!(object, upload, authenticated: authenticated)
    end

    def verify_object!(object, spec)
      authenticated = spec['authenticated']
      verify = spec.dig('actions', 'verify')

      lfs_client.verify!(object, verify, authenticated: authenticated)
    end

    def url
      params.fetch(:url)
    end

    def credentials
      params.fetch(:credentials)
    end

    def lfs_client
      strong_memoize(:lfs_client) do
        Gitlab::Lfs::Client.new(url, credentials: credentials)
      end
    end
  end
end
