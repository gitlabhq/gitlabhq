# frozen_string_literal: true

module Iam
  class ConsentController < ApplicationController
    before_action :authenticate_user!
    before_action :ensure_iam_enabled!
    before_action :verify_confirmed_email!
    before_action :require_consent_challenge!
    before_action :load_consent_data, only: [:show]
    before_action :load_cached_consent_data, only: [:accept, :reject]
    before_action :verify_subject_matches_user!

    layout 'minimal'

    feature_category :system_access
    urgency :low

    CONSENT_DATA_CACHE_TTL = 10.minutes
    CONSENT_DATA_CACHE_KEY_PREFIX = 'iam:consent_data'
    UPSTREAM_ERROR_REASONS = Set[:iam_request_failed, :service_unavailable].freeze

    def show
      if @consent_data[:skip_consent]
        return accept_challenge(
          challenge: @consent_challenge,
          client_id: @consent_data[:client_id],
          client_name: @consent_data[:client_name],
          requested_scopes: @consent_data[:requested_scopes],
          granted_scopes: @consent_data[:requested_scopes],
          client_scopes: @consent_data[:client_scopes]
        )
      end

      cache_consent_data(
        challenge: @consent_challenge,
        subject: @consent_data[:subject],
        client_id: @consent_data[:client_id],
        client_name: @consent_data[:client_name],
        requested_scopes: @consent_data[:requested_scopes],
        client_scopes: @consent_data[:client_scopes]
      )
      render :show
    end

    def accept
      # The consent form is all-or-nothing: granted_scopes matches requested_scopes
      # until partial scope selection is supported.
      accept_challenge(
        challenge: @consent_challenge,
        client_id: @cached_consent_data[:client_id],
        client_name: @cached_consent_data[:client_name],
        requested_scopes: @cached_consent_data[:requested_scopes],
        granted_scopes: @cached_consent_data[:requested_scopes],
        client_scopes: @cached_consent_data[:client_scopes]
      )
    end

    def reject
      handle_iam_result(
        Authn::IamService::RejectConsentChallengeService.new(
          challenge: @consent_challenge,
          user: current_user,
          client_id: @cached_consent_data[:client_id],
          client_name: @cached_consent_data[:client_name],
          requested_scopes: @cached_consent_data[:requested_scopes],
          client_scopes: @cached_consent_data[:client_scopes],
          ip_address: request.remote_ip,
          user_agent: request.user_agent
        ).execute
      )
    end

    private

    def accept_challenge(challenge:, client_id:, client_name:, requested_scopes:, granted_scopes:, client_scopes:)
      handle_iam_result(
        Authn::IamService::AcceptConsentChallengeService.new(
          challenge: challenge,
          user: current_user,
          granted_scopes: granted_scopes,
          client_id: client_id,
          client_name: client_name,
          requested_scopes: requested_scopes,
          client_scopes: client_scopes,
          ip_address: request.remote_ip,
          user_agent: request.user_agent
        ).execute
      )
    end

    def handle_iam_result(result)
      if result.success?
        redirect_to result.payload[:redirect_to], status: :see_other
      else
        status = UPSTREAM_ERROR_REASONS.include?(result.reason) ? :bad_gateway : :bad_request
        fail_consent(message: result.message, reason: result.reason, status: status)
      end
    end

    def cache_consent_data(challenge:, subject:, client_id:, client_name:, requested_scopes:, client_scopes:)
      Rails.cache.write(
        consent_data_cache_key(challenge),
        {
          subject: subject,
          client_id: client_id,
          client_name: client_name,
          requested_scopes: requested_scopes,
          client_scopes: client_scopes
        },
        expires_in: CONSENT_DATA_CACHE_TTL
      )
    end

    def require_consent_challenge!
      @consent_challenge = consent_challenge_param
      return if @consent_challenge.present?

      fail_consent(message: 'Missing consent challenge', status: :bad_request)
    end

    def load_consent_data
      result = Authn::IamService::GetConsentChallengeService.new(
        challenge: @consent_challenge
      ).execute

      return handle_iam_result(result) if result.error?

      @consent_data = result.payload
    end

    def load_cached_consent_data
      key = consent_data_cache_key(@consent_challenge)
      @cached_consent_data = Rails.cache.read(key)

      if @cached_consent_data.nil?
        return fail_consent(message: 'Consent session expired or already used',
          status: :bad_request)
      end

      Rails.cache.delete(key)
    end

    def verify_subject_matches_user!
      subject = @consent_data&.dig(:subject) || @cached_consent_data&.dig(:subject)
      return if subject.to_s == current_user.id.to_s

      fail_consent(message: 'IAM subject does not match current user', status: :bad_request)
    end

    def ensure_iam_enabled!
      return if Feature.enabled?(:iam_svc_login, :instance) && Authn::IamAuthService.enabled?

      render_404
    end

    def verify_confirmed_email!
      return if current_user.confirmed?

      fail_consent(message: 'User email not confirmed', status: :bad_request)
    end

    def consent_challenge_param
      params.permit(:consent_challenge)[:consent_challenge]
    end

    def consent_data_cache_key(challenge)
      "#{CONSENT_DATA_CACHE_KEY_PREFIX}:#{current_user.id}:#{challenge}"
    end

    def fail_consent(message:, status:, reason: nil)
      Gitlab::AuthLogger.error(
        {
          message: message,
          reason: reason,
          Labkit::Fields::GL_USER_ID => current_user.id
        }.compact
      )

      render :error, status: status
    end
  end
end
