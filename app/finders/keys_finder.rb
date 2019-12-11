# frozen_string_literal: true
class KeysFinder
  InvalidFingerprint = Class.new(StandardError)
  GitLabAccessDeniedError = Class.new(StandardError)

  FINGERPRINT_ATTRIBUTES = {
    'sha256' => 'fingerprint_sha256',
    'md5' => 'fingerprint'
  }.freeze

  def initialize(current_user, params)
    @current_user = current_user
    @params = params
  end

  def execute
    raise GitLabAccessDeniedError unless current_user.admin?
    raise InvalidFingerprint unless valid_fingerprint_param?

    Key.where(fingerprint_query).first # rubocop: disable CodeReuse/ActiveRecord
  end

  private

  attr_reader :current_user, :params

  def valid_fingerprint_param?
    if fingerprint_type == "sha256"
      Base64.decode64(fingerprint).length == 32
    else
      fingerprint =~ /^(\h{2}:){15}\h{2}/
    end
  end

  def fingerprint_query
    fingerprint_attribute = FINGERPRINT_ATTRIBUTES[fingerprint_type]

    Key.arel_table[fingerprint_attribute].eq(fingerprint)
  end

  def fingerprint_type
    if params[:fingerprint].start_with?(/sha256:|SHA256:/)
      "sha256"
    else
      "md5"
    end
  end

  def fingerprint
    if fingerprint_type == "sha256"
      params[:fingerprint].gsub(/sha256:|SHA256:/, "")
    else
      params[:fingerprint]
    end
  end
end
