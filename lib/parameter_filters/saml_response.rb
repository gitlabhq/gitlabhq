# frozen_string_literal: true

module ParameterFilters
  class SamlResponse
    def self.log(value)
      return value unless value.presence

      response = OneLogin::RubySaml::Response.new(value)

      saml_response_details = {
        issuer: response.issuers,
        name_id: response.name_id,
        name_id_format: response.name_id_format,
        name_id_spnamequalifier: response.name_id_spnamequalifier,
        name_id_namequalifier: response.name_id_namequalifier,
        destination: response.destination,
        audiences: response.audiences,
        attributes: response.attributes.to_h,
        in_response_to: response.in_response_to,
        allowed_clock_drift: response.allowed_clock_drift,
        success: response.success?,
        status_code: response.status_code,
        status_message: response.status_message,
        session_index: response.sessionindex,
        assertion_encrypted: response.assertion_encrypted?,
        response_id: response.response_id,
        assertion_id: response.assertion_id
      }
      Gitlab::AuthLogger.info(payload_type: 'saml_response', saml_response: saml_response_details)
    rescue OneLogin::RubySaml::ValidationError, REXML::ParseException => e
      Gitlab::AuthLogger.error(payload_type: 'saml_response', error: e.message)
    end
  end
end
