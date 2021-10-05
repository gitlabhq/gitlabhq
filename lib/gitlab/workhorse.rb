# frozen_string_literal: true

require 'base64'
require 'json'
require 'securerandom'
require 'uri'

module Gitlab
  class Workhorse
    SEND_DATA_HEADER = 'Gitlab-Workhorse-Send-Data'
    VERSION_FILE = 'GITLAB_WORKHORSE_VERSION'
    INTERNAL_API_CONTENT_TYPE = 'application/vnd.gitlab-workhorse+json'
    INTERNAL_API_REQUEST_HEADER = 'Gitlab-Workhorse-Api-Request'
    NOTIFICATION_CHANNEL = 'workhorse:notifications'
    ALLOWED_GIT_HTTP_ACTIONS = %w[git_receive_pack git_upload_pack info_refs].freeze
    DETECT_HEADER = 'Gitlab-Workhorse-Detect-Content-Type'
    ARCHIVE_FORMATS = %w(zip tar.gz tar.bz2 tar).freeze

    include JwtAuthenticatable

    class << self
      def git_http_ok(repository, repo_type, user, action, show_all_refs: false)
        raise "Unsupported action: #{action}" unless ALLOWED_GIT_HTTP_ACTIONS.include?(action.to_s)

        attrs = {
          GL_ID: Gitlab::GlId.gl_id(user),
          GL_REPOSITORY: repo_type.identifier_for_container(repository.container),
          GL_USERNAME: user&.username,
          ShowAllRefs: show_all_refs,
          Repository: repository.gitaly_repository.to_h,
          GitConfigOptions: [],
          GitalyServer: {
            address: Gitlab::GitalyClient.address(repository.storage),
            token: Gitlab::GitalyClient.token(repository.storage),
            features: Feature::Gitaly.server_feature_flags(repository.project)
          }
        }

        # Custom option for git-receive-pack command
        receive_max_input_size = Gitlab::CurrentSettings.receive_max_input_size.to_i
        if receive_max_input_size > 0
          attrs[:GitConfigOptions] << "receive.maxInputSize=#{receive_max_input_size.megabytes}"
        end

        attrs
      end

      def send_git_blob(repository, blob)
        params = {
          'GitalyServer' => gitaly_server_hash(repository),
          'GetBlobRequest' => {
            repository: repository.gitaly_repository.to_h,
            oid: blob.id,
            limit: -1
          }
        }

        [
          SEND_DATA_HEADER,
          "git-blob:#{encode(params)}"
        ]
      end

      def send_git_archive(repository, ref:, format:, append_sha:, path: nil)
        format ||= 'tar.gz'
        format = format.downcase

        metadata = repository.archive_metadata(
          ref,
          Gitlab.config.gitlab.repository_downloads_path,
          format,
          append_sha: append_sha,
          path: path
        )

        raise "Repository or ref not found" if metadata.empty?

        params = send_git_archive_params(repository, metadata, path, archive_format(format))

        # If present, DisableCache must be a Boolean. Otherwise
        # workhorse ignores it.
        params['DisableCache'] = true if git_archive_cache_disabled?
        params['GitalyServer'] = gitaly_server_hash(repository)

        [
          SEND_DATA_HEADER,
          "git-archive:#{encode(params)}"
        ]
      end

      def send_git_snapshot(repository)
        params = {
          'GitalyServer' => gitaly_server_hash(repository),
          'GetSnapshotRequest' => Gitaly::GetSnapshotRequest.new(
            repository: repository.gitaly_repository
          ).to_json
        }

        [
          SEND_DATA_HEADER,
          "git-snapshot:#{encode(params)}"
        ]
      end

      def send_git_diff(repository, diff_refs)
        params = {
          'GitalyServer' => gitaly_server_hash(repository),
          'RawDiffRequest' => Gitaly::RawDiffRequest.new(
            gitaly_diff_or_patch_hash(repository, diff_refs)
          ).to_json
        }

        [
          SEND_DATA_HEADER,
          "git-diff:#{encode(params)}"
        ]
      end

      def send_git_patch(repository, diff_refs)
        params = {
          'GitalyServer' => gitaly_server_hash(repository),
          'RawPatchRequest' => Gitaly::RawPatchRequest.new(
            gitaly_diff_or_patch_hash(repository, diff_refs)
          ).to_json
        }

        [
          SEND_DATA_HEADER,
          "git-format-patch:#{encode(params)}"
        ]
      end

      def send_artifacts_entry(file, entry)
        archive = file.file_storage? ? file.path : file.url

        params = {
          'Archive' => archive,
          'Entry' => Base64.encode64(entry.to_s)
        }

        [
          SEND_DATA_HEADER,
          "artifacts-entry:#{encode(params)}"
        ]
      end

      def send_url(url, allow_redirects: false)
        params = {
          'URL' => url,
          'AllowRedirects' => allow_redirects
        }

        [
          SEND_DATA_HEADER,
          "send-url:#{encode(params)}"
        ]
      end

      def send_scaled_image(location, width, content_type)
        params = {
          'Location' => location,
          'Width' => width,
          'ContentType' => content_type
        }

        [
          SEND_DATA_HEADER,
          "send-scaled-img:#{encode(params)}"
        ]
      end

      def channel_websocket(channel)
        details = {
          'Channel' => {
            'Subprotocols' => channel[:subprotocols],
            'Url' => channel[:url],
            'Header' => channel[:headers],
            'MaxSessionTime' => channel[:max_session_time]
          }
        }
        details['Channel']['CAPem'] = channel[:ca_pem] if channel.key?(:ca_pem)

        details
      end

      def version
        path = Rails.root.join(VERSION_FILE)
        path.readable? ? path.read.chomp : 'unknown'
      end

      def verify_api_request!(request_headers)
        decode_jwt(request_headers[INTERNAL_API_REQUEST_HEADER])
      end

      def decode_jwt(encoded_message)
        decode_jwt_for_issuer('gitlab-workhorse', encoded_message)
      end

      def secret_path
        Gitlab.config.workhorse.secret_file
      end

      def set_key_and_notify(key, value, expire: nil, overwrite: true)
        Gitlab::Redis::SharedState.with do |redis|
          result = redis.set(key, value, ex: expire, nx: !overwrite)
          if result
            redis.publish(NOTIFICATION_CHANNEL, "#{key}=#{value}")
            value
          else
            redis.get(key)
          end
        end
      end

      protected

      # This is the outermost encoding of a senddata: header. It is safe for
      # inclusion in HTTP response headers
      def encode(hash)
        Base64.urlsafe_encode64(Gitlab::Json.dump(hash))
      end

      # This is for encoding individual fields inside the senddata JSON that
      # contain binary data. In workhorse, the corresponding struct field should
      # be type []byte
      def encode_binary(binary)
        Base64.encode64(binary)
      end

      def gitaly_server_hash(repository)
        {
          address: Gitlab::GitalyClient.address(repository.shard),
          token: Gitlab::GitalyClient.token(repository.shard),
          features: Feature::Gitaly.server_feature_flags(repository.project)
        }
      end

      def gitaly_diff_or_patch_hash(repository, diff_refs)
        {
          repository: repository.gitaly_repository,
          left_commit_id: diff_refs.base_sha,
          right_commit_id: diff_refs.head_sha
        }
      end

      def git_archive_cache_disabled?
        ENV['WORKHORSE_ARCHIVE_CACHE_DISABLED'].present? || Feature.enabled?(:workhorse_archive_cache_disabled)
      end

      def archive_format(format)
        case format
        when "tar.bz2", "tbz", "tbz2", "tb2", "bz2"
          Gitaly::GetArchiveRequest::Format::TAR_BZ2
        when "tar"
          Gitaly::GetArchiveRequest::Format::TAR
        when "zip"
          Gitaly::GetArchiveRequest::Format::ZIP
        else
          Gitaly::GetArchiveRequest::Format::TAR_GZ
        end
      end

      def send_git_archive_params(repository, metadata, path, format)
        {
          'ArchivePath' => metadata['ArchivePath'],
          'GetArchiveRequest' => encode_binary(
            Gitaly::GetArchiveRequest.new(
              repository: repository.gitaly_repository,
              commit_id: metadata['CommitId'],
              prefix: metadata['ArchivePrefix'],
              format: format,
              path: path.presence || "",
              include_lfs_blobs: true
            ).to_proto
          )
        }
      end
    end
  end
end
