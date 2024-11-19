# frozen_string_literal: true

module Gitlab
  class HTTP
    BlockedUrlError = Gitlab::HTTP_V2::BlockedUrlError
    RedirectionTooDeep = Gitlab::HTTP_V2::RedirectionTooDeep
    ReadTotalTimeout = Gitlab::HTTP_V2::ReadTotalTimeout
    HeaderReadTimeout = Gitlab::HTTP_V2::HeaderReadTimeout
    SilentModeBlockedError = Gitlab::HTTP_V2::SilentModeBlockedError

    HTTP_TIMEOUT_ERRORS = Gitlab::HTTP_V2::HTTP_TIMEOUT_ERRORS
    HTTP_ERRORS = Gitlab::HTTP_V2::HTTP_ERRORS

    DEFAULT_TIMEOUT_OPTIONS = {
      open_timeout: 10,
      read_timeout: 20,
      write_timeout: 30
    }.freeze
    DEFAULT_READ_TOTAL_TIMEOUT = 30.seconds

    # We are explicitly assigning these constants because they are used in the codebase.
    Error = HTTParty::Error
    Response = HTTParty::Response
    ResponseError = HTTParty::ResponseError
    CookieHash = HTTParty::CookieHash

    class << self
      ::Gitlab::HTTP_V2::SUPPORTED_HTTP_METHODS.each do |method|
        define_method(method) do |path, options = {}, &block|
          ::Gitlab::HTTP_V2.public_send(method, path, http_v2_options(options), &block) # rubocop:disable GitlabSecurity/PublicSend -- method is validated to make sure it is one of the methods in Gitlab::HTTP_V2::SUPPORTED_HTTP_METHODS
        end
      end

      def try_get(path, options = {}, &block)
        get(path, options, &block)
      rescue *HTTP_ERRORS
        nil
      end

      # TODO: This method is subject to be removed
      # We have this for now because we explicitly use the `perform_request` method in some places.
      def perform_request(http_method, path, options, &block)
        method_name = http_method::METHOD.downcase.to_sym

        unless ::Gitlab::HTTP_V2::SUPPORTED_HTTP_METHODS.include?(method_name)
          raise ArgumentError, "Unsupported HTTP method: '#{method_name}'."
        end

        # Use `::Gitlab::HTTP_V2.get/post/...` methods
        ::Gitlab::HTTP_V2.public_send(method_name, path, http_v2_options(options), &block) # rubocop:disable GitlabSecurity/PublicSend -- method is validated to make sure it is one of the methods in Gitlab::HTTP_V2::SUPPORTED_HTTP_METHODS
      end

      private

      def http_v2_options(options)
        # TODO: until we remove `allow_object_storage` from all places.
        if options.delete(:allow_object_storage)
          options[:extra_allowed_uris] = ObjectStoreSettings.enabled_endpoint_uris
        end

        # Configure HTTP_V2 Client
        {
          allow_local_requests: Gitlab::CurrentSettings.allow_local_requests_from_web_hooks_and_services?,
          deny_all_requests_except_allowed: Gitlab::CurrentSettings.deny_all_requests_except_allowed?,
          dns_rebinding_protection_enabled: Gitlab::CurrentSettings.dns_rebinding_protection_enabled?,
          outbound_local_requests_allowlist: Gitlab::CurrentSettings.outbound_local_requests_whitelist, # rubocop:disable Naming/InclusiveLanguage -- existing setting
          silent_mode_enabled: Gitlab::SilentMode.enabled?
        }.merge(options)
      end
    end
  end
end
