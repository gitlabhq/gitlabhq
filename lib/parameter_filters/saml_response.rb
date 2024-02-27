# frozen_string_literal: true

module ParameterFilters
  class SamlResponse
    def self.filter(value)
      return value unless value.presence

      raw_response = if Base64.decode64(value).scan(/[^[:ascii:]]/).count == 0
                       Base64.decode64(value)
                     else
                       value
                     end

      response = Nokogiri::XML(raw_response) do |config|
        config.options = Nokogiri::XML::ParseOptions::NONET
      end

      [
        '/samlp:Response/@IssueInstant',
        '/samlp:Response/saml:Assertion/@IssueInstant',
        '/samlp:Response/saml:Assertion/saml:Conditions/@NotBefore',
        '/samlp:Response/saml:Assertion/saml:Conditions/@NotOnOrAfter',
        '/samlp:Response/saml:Assertion/saml:AuthnStatement/@AuthnInstant',
        '/samlp:Response/saml:Assertion/saml:AuthnStatement/@SessionNotOnOrAfter'
      ].each do |xpath|
        response.at_xpath(xpath).value = 'REDACTED'
      end

      [
        ['//ds:Signature/ds:SignatureValue', { ds: 'http://www.w3.org/2000/09/xmldsig#' }],
        ['//ds:Signature/ds:SignedInfo/ds:Reference/ds:DigestValue', { ds: 'http://www.w3.org/2000/09/xmldsig#' }]
      ].each do |xpath, namespace|
        response.at_xpath(xpath, namespace.presence).content = 'REDACTED'
      end

      response.to_xml

    rescue Nokogiri::XML::SyntaxError
      'REDACTED'
    end
  end
end
