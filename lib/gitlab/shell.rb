# frozen_string_literal: true

require 'securerandom'

module Gitlab
  # This class is an artifact of a time when common repository operations were
  # performed by calling out to scripts in the gitlab-shell project. Now, these
  # operations are all performed by Gitaly, and are mostly accessible through
  # the Repository class. Prefer using a Repository to functionality here.
  #
  # Legacy code relating to namespaces still relies on Gitlab::Shell; it can be
  # converted to a module once https://gitlab.com/groups/gitlab-org/-/epics/2320
  # is completed. https://gitlab.com/gitlab-org/gitlab/-/issues/25095 tracks it.
  class Shell
    Error = Class.new(StandardError)

    API_HEADER = 'Gitlab-Shell-Api-Request'
    JWT_ISSUER = 'gitlab-shell'

    class << self
      def verify_api_request(headers)
        payload, header = JSONWebToken::HMACToken.decode(headers[API_HEADER], secret_token)
        return unless payload['iss'] == JWT_ISSUER

        [payload, header]
      rescue JWT::DecodeError, JWT::ExpiredSignature, JWT::ImmatureSignature => ex
        Gitlab::ErrorTracking.track_exception(ex)
        nil
      end

      def header_set?(headers)
        headers[API_HEADER].present?
      end

      # Retrieve GitLab Shell secret token
      #
      # @return [String] secret token
      def secret_token
        @secret_token ||= File.read(Gitlab.config.gitlab_shell.secret_file).chomp
      end

      # Ensure gitlab shell has a secret token stored in the secret_file
      # if that was never generated, generate a new one
      def ensure_secret_token!
        return if File.exist?(File.join(Gitlab.config.gitlab_shell.path, '.gitlab_shell_secret'))

        generate_and_link_secret_token
      end

      # Returns required GitLab shell version
      #
      # @return [String] version from the manifest file
      def version_required
        @version_required ||= File.read(Rails.root
                                        .join('GITLAB_SHELL_VERSION')).strip
      end

      # Return GitLab shell version
      #
      # @return [String] version
      def version
        @version ||= File.read(gitlab_shell_version_file).chomp if File.readable?(gitlab_shell_version_file)
      end

      private

      def gitlab_shell_path
        File.expand_path(Gitlab.config.gitlab_shell.path)
      end

      def gitlab_shell_version_file
        File.join(gitlab_shell_path, 'VERSION')
      end

      # Create (if necessary) and link the secret token file
      def generate_and_link_secret_token
        secret_file = Gitlab.config.gitlab_shell.secret_file
        shell_path = Gitlab.config.gitlab_shell.path

        unless File.size?(secret_file)
          # Generate a new token of 16 random hexadecimal characters and store it in secret_file.
          @secret_token = SecureRandom.hex(16)
          File.write(secret_file, @secret_token)
        end

        link_path = File.join(shell_path, '.gitlab_shell_secret')
        if File.exist?(shell_path) && !File.exist?(link_path)
          # It could happen that link_path is a broken symbolic link.
          # In that case !File.exist?(link_path) is true, but we still want to overwrite the (broken) symbolic link.
          FileUtils.ln_sf(secret_file, link_path)
        end
      end
    end

    # Check if repository exists on disk
    #
    # @example Check if repository exists
    #   repository_exists?('default', 'gitlab-org/gitlab.git')
    #
    # @return [Boolean] whether repository exists or not
    # @param [String] storage project's storage path
    # @param [Object] dir_name repository dir name
    #
    # @deprecated
    def repository_exists?(storage, dir_name)
      Gitlab::Git::Repository.new(storage, dir_name, nil, nil).exists?
    rescue GRPC::Internal
      false
    end
  end
end
