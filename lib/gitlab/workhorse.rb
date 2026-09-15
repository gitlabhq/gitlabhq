# frozen_string_literal: true

require 'base64'
require 'json'
require 'securerandom'
require 'uri'

module Gitlab
  class Workhorse
    ArchiveNotFoundError = Class.new(StandardError)

    SEND_DATA_HEADER = 'Gitlab-Workhorse-Send-Data'
    SEND_DEPENDENCY_CONTENT_TYPE_HEADER = 'Workhorse-Proxy-Content-Type'
    VERSION_FILE = 'GITLAB_WORKHORSE_VERSION'
    INTERNAL_API_CONTENT_TYPE = 'application/vnd.gitlab-workhorse+json'
    INTERNAL_API_REQUEST_HEADER = 'Gitlab-Workhorse-Api-Request'
    NOTIFICATION_PREFIX = 'workhorse:notifications:'
    ALLOWED_GIT_HTTP_ACTIONS = %w[git_receive_pack git_upload_pack info_refs].freeze
    DETECT_HEADER = 'Gitlab-Workhorse-Detect-Content-Type'
    # Body formats the send-url streaming rewrite understands. Must stay in step
    # with the switch in workhorse/internal/sendurl/sendurl.go.
    TRANSFORM_FORMATS = %i[json html].freeze
    ARCHIVE_FORMATS = %w[zip tar.gz tar.bz2 tar].freeze

    # Maximum age of the Gitlab-Workhorse-Api-Request JWT accepted by
    # `verify_api_request!`. Workhorse stamps `iat` on every request (see
    # workhorse/internal/secret/roundtripper.go), and Rails rejects tokens
    # whose `iat` is older than this window. Caps the replay value of a
    # leaked JWT regardless of whether the workhorse secret has rotated.
    # A leaked senddata payload is also bounded by the freshness of the
    # JWT that authorized it, so this also caps senddata replayability.
    #
    # Defaults to 90 seconds to absorb clock skew across distributed
    # deployments and the request's own in-flight time; narrow further once
    # production telemetry confirms the floor. Operators can override via
    # the `WORKHORSE_API_REQUEST_JWT_VALIDITY_SECONDS` environment variable
    # (positive integer); an unset or `0` value falls back to the default.
    API_REQUEST_JWT_VALIDITY = (ENV.fetch('WORKHORSE_API_REQUEST_JWT_VALIDITY_SECONDS', 0).to_i.nonzero? || 90).seconds

    include JwtAuthenticatable

    class << self
      def git_http_ok(
        repository, repo_type, user, action, show_all_refs: false, need_audit: false,
        authentication_context: {})
        raise "Unsupported action: #{action}" unless ALLOWED_GIT_HTTP_ACTIONS.include?(action.to_s)

        attrs = {
          GL_ID: Gitlab::GlId.gl_id(user),
          GL_REPOSITORY: repo_type.identifier_for_container(repository.container),
          GL_USERNAME: user&.username,
          ShowAllRefs: show_all_refs,
          NeedAudit: need_audit,
          Repository: repository.gitaly_repository.to_h,
          GitConfigOptions: [],
          GitalyServer: {
            address: Gitlab::GitalyClient.address(repository.storage),
            token: Gitlab::GitalyClient.token(repository.storage),
            call_metadata: Feature::Gitaly.server_feature_flags(
              user: ::Feature::Gitaly.user_actor(user),
              repository: repository,
              project: ::Feature::Gitaly.project_actor(repository.container),
              group: ::Feature::Gitaly.group_actor(repository.container)
            )
          }
        }

        ::Gitlab::Auth::Identity.currently_linked do |identity|
          attrs[:GlScopedUserID] = identity.scoped_user.id.to_s
        end

        if authentication_context[:authentication_method] == :ci_job_token
          attrs[:GlBuildID] = authentication_context[:authentication_method_id].to_s
        end

        if repo_type == Gitlab::GlRepository::PROJECT
          project = repository.container
          root_namespace = project&.root_namespace

          attrs[:ProjectID] = project.id if project
          attrs[:RootNamespaceID] = root_namespace.id if root_namespace
        end

        # Custom option for git-receive-pack command
        receive_max_input_size = Gitlab::CurrentSettings.receive_max_input_size.to_i
        if receive_max_input_size > 0
          attrs[:GitConfigOptions] << "receive.maxInputSize=#{receive_max_input_size.megabytes}"
        end

        attrs[:GitalyServer][:call_metadata].merge!(
          'user_id' => attrs[:GL_ID].presence,
          'username' => attrs[:GL_USERNAME].presence,
          'remote_ip' => Gitlab::ApplicationContext.current_context_attribute(:remote_ip).presence,
          'retry_config' => retry_config
        ).compact!

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

      def send_git_archive( # rubocop:disable Metrics/ParameterLists -- each parameter is a distinct, required part of the archive request. Switching to **kwargs would mask complexity and make it harder to understand the method signature.
        repository,
        ref:,
        format:,
        append_sha:,
        path: nil,
        include_lfs_blobs: true,
        exclude_paths: [],
        client_name: nil,
        ref_type: nil,
        metadata: nil
      )
        format ||= 'tar.gz'
        format = format.downcase

        # Callers can pass already-resolved metadata (for example, from the
        # ArchiveHeaderBuilder used to compute the ETag) so the headers and the
        # archive body describe the same commit instead of resolving the ref twice.
        metadata ||= repository.archive_metadata(
          ref,
          Gitlab.config.gitlab.repository_downloads_path,
          format,
          append_sha: append_sha,
          path: path,
          ref_type: ref_type,
          include_lfs_blobs: include_lfs_blobs,
          exclude_paths: exclude_paths
        )

        raise ArchiveNotFoundError, "Repository or ref not found" if metadata.empty?

        params = send_git_archive_params(repository, metadata, path, archive_format(format), include_lfs_blobs,
          exclude_paths)

        # If present, DisableCache must be a Boolean. Otherwise
        # workhorse ignores it.
        params['DisableCache'] = true if git_archive_cache_disabled?
        params['UseArchiveCleaner'] = git_archive_cache_cleaner_enabled?
        params['GitalyServer'] = gitaly_server_hash(repository, client_name: client_name)

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

      def send_changed_paths(repository, requests, client_name: nil)
        params = {
          'GitalyServer' => gitaly_server_hash(repository, client_name: client_name),
          'FindChangedPathsRequest' => Gitaly::FindChangedPathsRequest.new(
            repository: repository.gitaly_repository,
            requests: requests
          ).to_json
        }

        [
          SEND_DATA_HEADER,
          "git-changed-paths:#{encode(params)}"
        ]
      end

      def send_list_blobs(repository, revisions, bytes_limit:, client_name: nil)
        params = {
          'GitalyServer' => gitaly_server_hash(repository, client_name: client_name),
          'ListBlobsRequest' => Gitaly::ListBlobsRequest.new(
            repository: repository.gitaly_repository,
            revisions: revisions,
            bytes_limit: bytes_limit,
            with_paths: true
          ).to_json
        }

        [
          SEND_DATA_HEADER,
          "git-list-blobs:#{encode(params)}"
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

      # response_statuses can be set for 'error' and 'timeout'. They are optional.
      # Their values must be a symbol accepted by Rack::Utils::SYMBOL_TO_STATUS_CODE.
      # Example: response_statuses : { error: :internal_server_error, timeout: :bad_request }
      # timeouts can be given for the opening the connection and reading the response headers.
      # Their values must be given in seconds.
      # Example: timeouts: { open: 5, read: 5 }
      # rubocop:disable Metrics/ParameterLists -- all arguments needed
      def send_url(
        url,
        allow_localhost: true,
        allow_redirects: false,
        method: 'GET',
        body: nil,
        ssrf_filter: false,
        headers: {},
        timeouts: {},
        response_statuses: {},
        response_headers: {},
        allowed_endpoints: [],
        restrict_forwarded_response_headers: {},
        transform_config: {}
      )
        params = {
          'URL' => url,
          'AllowRedirects' => allow_redirects,
          'AllowLocalhost' => allow_localhost,
          'AllowedEndpoints' => allowed_endpoints,
          'SSRFFilter' => ssrf_filter,
          'Body' => body.to_s,
          'Header' => headers.transform_values { |v| Array.wrap(v) },
          'ResponseHeaders' => response_headers.transform_values { |v| Array.wrap(v) },
          'Method' => method
        }.merge(restrict_forwarded_response_headers_params(restrict_forwarded_response_headers)).compact

        if timeouts.present?
          params['DialTimeout'] = "#{timeouts[:open]}s" if timeouts[:open]
          params['ResponseHeaderTimeout'] = "#{timeouts[:read]}s" if timeouts[:read]
        end

        if response_statuses.present?
          if response_statuses[:error]
            params['ErrorResponseStatus'] = Rack::Utils::SYMBOL_TO_STATUS_CODE[response_statuses[:error]]
          end

          if response_statuses[:timeout]
            params['TimeoutResponseStatus'] = Rack::Utils::SYMBOL_TO_STATUS_CODE[response_statuses[:timeout]]
          end
        end

        params['TransformConfig'] = transform_config_params(transform_config) if transform_config.present?

        [
          SEND_DATA_HEADER,
          "send-url:#{encode(params.compact)}"
        ]
      end
      # rubocop:enable Metrics/ParameterLists

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

      def send_dependency(
        headers,
        url,
        allow_localhost: true,
        upload_config: {},
        response_headers: {},
        ssrf_filter: false,
        allowed_endpoints: [],
        restrict_forwarded_response_headers: {})
        params = {
          'AllowLocalhost' => allow_localhost,
          'AllowedEndpoints' => allowed_endpoints,
          'Headers' => headers.transform_values { |v| Array.wrap(v) },
          'ResponseHeaders' => response_headers.transform_values { |v| Array.wrap(v) },
          'SSRFFilter' => ssrf_filter,
          'Url' => url,
          'UploadConfig' => {
            'Method' => upload_config[:method],
            'Url' => upload_config[:url],
            'Headers' => (upload_config[:headers] || {}).transform_values { |v| Array.wrap(v) },
            'AuthorizedUploadResponse' => upload_config[:authorized_upload_response] || {}
          }.compact_blank!
        }.merge(restrict_forwarded_response_headers_params(restrict_forwarded_response_headers))
        params.compact_blank!
        [
          SEND_DATA_HEADER,
          "send-dependency:#{encode(params)}"
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

      # Verifies the `Gitlab-Workhorse-Api-Request` JWT prepended to a request
      # by Workhorse's signing round-tripper. Enforces `iat_after` against
      # `API_REQUEST_JWT_VALIDITY` so a captured token expires quickly
      # regardless of secret rotation.
      def verify_api_request!(request_headers)
        decode_jwt(request_headers[INTERNAL_API_REQUEST_HEADER],
          issuer: 'gitlab-workhorse',
          iat_after: API_REQUEST_JWT_VALIDITY.ago)
      end

      # Issuer-only JWT decode. Used by callers that handle other Workhorse
      # JWT payloads whose signers do not stamp `iat` (notably the multipart
      # middleware, which decodes the upload-finalize token). Leave the
      # `iat_after` enforcement on `verify_api_request!` only.
      def decode_jwt_with_issuer(encoded_message)
        decode_jwt(encoded_message, issuer: 'gitlab-workhorse')
      end

      def secret_path
        Gitlab.config.workhorse.secret_file
      end

      def cleanup_key(key)
        with_redis { |redis| redis.del(key) }
      end

      def set_key_and_notify(key, value, expire: nil, overwrite: true)
        with_redis do |redis|
          result = redis.set(key, value, ex: expire, nx: !overwrite)
          if result
            redis.publish(NOTIFICATION_PREFIX + key, value)

            value
          else
            redis.get(key)
          end
        end
      end

      def detect_content_type
        [
          Gitlab::Workhorse::DETECT_HEADER,
          'true'
        ]
      end

      protected

      def with_redis(&blk)
        Gitlab::Redis::Workhorse.with(&blk) # rubocop:disable CodeReuse/ActiveRecord
      end

      def encode(hash)
        Base64.urlsafe_encode64(Gitlab::Json.dump(hash))
      end

      # This is for encoding individual fields inside the senddata JSON that
      # contain binary data. In workhorse, the corresponding struct field should
      # be type []byte
      def encode_binary(binary)
        Base64.encode64(binary)
      end

      def gitaly_server_hash(repository, client_name: nil)
        metadata = Feature::Gitaly.server_feature_flags(
          user: ::Feature::Gitaly.user_actor,
          repository: repository,
          project: ::Feature::Gitaly.project_actor(repository.container),
          group: ::Feature::Gitaly.group_actor(repository.container)
        )
        metadata['retry_config'] = retry_config
        metadata['client_name'] = client_name if client_name.present?
        # Forward the requesting user and IP so Gitaly attributes these RPCs and
        # applies the authenticated (vs unauthenticated) concurrency limits,
        # matching what Gitlab::GitalyClient#request_kwargs already does for
        # direct gRPC calls. Anonymous requests simply omit the user identity.
        metadata.merge!(Gitlab::GitalyClient.application_context_metadata)

        {
          address: Gitlab::GitalyClient.address(repository.shard),
          token: Gitlab::GitalyClient.token(repository.shard),
          call_metadata: metadata
        }
      end

      def retry_config
        Gitlab::Json.dump(Gitlab::GitalyClient.retry_policy)
      end

      def gitaly_diff_or_patch_hash(repository, diff_refs)
        left_commit_id = diff_refs.base_sha

        # If `base_sha` is a blank ref, it means the commit has no parent (e.g. the
        # initial commit of a repository or the first commit on an orphaned branch).
        # We use `empty_tree_id` so Gitaly can compute the diff against an empty tree
        # instead of returning an empty response.
        left_commit_id = repository.empty_tree_id if Gitlab::Git.blank_ref?(left_commit_id)

        {
          repository: repository.gitaly_repository,
          left_commit_id: left_commit_id,
          right_commit_id: diff_refs.head_sha
        }
      end

      def git_archive_cache_disabled?
        ENV['WORKHORSE_ARCHIVE_CACHE_DISABLED'].present? || Feature.enabled?(:workhorse_archive_cache_disabled)
      end

      def git_archive_cache_cleaner_enabled?
        ENV["WORKHORSE_ARCHIVE_CACHE_CLEANER_DISABLED"].blank?
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

      def send_git_archive_params(repository, metadata, path, format, include_lfs_blobs, exclude_paths)
        {
          'ArchivePath' => metadata['ArchivePath'],
          'StoragePath' => metadata['StoragePath'],
          'GetArchiveRequest' => encode_binary(
            Gitaly::GetArchiveRequest.new(
              repository: repository.gitaly_repository,
              commit_id: metadata['CommitId'],
              prefix: metadata['ArchivePrefix'],
              format: format,
              path: Gitlab::EncodingHelper.encode_binary(path.presence || ""),
              include_lfs_blobs: include_lfs_blobs,
              exclude: exclude_paths.map { |exclude_path| Gitlab::EncodingHelper.encode_binary(exclude_path) }
            ).to_proto
          )
        }
      end

      def transform_config_params(transform_config)
        raise ArgumentError, "transform_config requires :key, :from, and :to" \
          unless transform_config[:key].present? && transform_config[:from].present? && transform_config[:to].present?

        # Workhorse routes any format it does not recognise to the JSON transform,
        # so an unknown or misspelled value would rewrite an HTML document as if it
        # were JSON rather than fail.
        format = transform_config.fetch(:format, :json)
        raise ArgumentError, "transform_config :format must be one of #{TRANSFORM_FORMATS.join(', ')}" \
          unless TRANSFORM_FORMATS.include?(format)

        {
          'Format' => format.to_s,
          'Key' => transform_config[:key],
          'From' => transform_config[:from],
          'To' => transform_config[:to]
        }
      end

      def restrict_forwarded_response_headers_params(params)
        params[:enabled] = false unless params.key?(:enabled)
        {
          'RestrictForwardedResponseHeaders' => {
            'Enabled' => params[:enabled],
            'AllowList' => params[:allow_list] || []
          }
        }.compact_blank!
      end
    end
  end
end

Gitlab::Workhorse.prepend_mod
