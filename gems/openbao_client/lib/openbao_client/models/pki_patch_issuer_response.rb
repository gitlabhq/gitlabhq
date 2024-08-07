=begin
#OpenBao API

#HTTP API that gives you full access to OpenBao. All API routes are prefixed with `/v1/`.

The version of the OpenAPI document: 2.0.0

Generated by: https://openapi-generator.tech
Generator version: 7.7.0

=end

require 'date'
require 'time'

module OpenbaoClient
  class PkiPatchIssuerResponse
    # CA Chain
    attr_accessor :ca_chain

    # Certificate
    attr_accessor :certificate

    # CRL Distribution Points
    attr_accessor :crl_distribution_points

    # Delta CRL Distribution Points
    attr_accessor :delta_crl_distribution_points

    # Whether or not templating is enabled for AIA fields
    attr_accessor :enable_aia_url_templating

    # Issuer Id
    attr_accessor :issuer_id

    # Issuer Name
    attr_accessor :issuer_name

    # Issuing Certificates
    attr_accessor :issuing_certificates

    # Key Id
    attr_accessor :key_id

    # Leaf Not After Behavior
    attr_accessor :leaf_not_after_behavior

    # Manual Chain
    attr_accessor :manual_chain

    # OCSP Servers
    attr_accessor :ocsp_servers

    # Revocation Signature Alogrithm
    attr_accessor :revocation_signature_algorithm

    attr_accessor :revocation_time

    attr_accessor :revocation_time_rfc3339

    # Revoked
    attr_accessor :revoked

    # Usage
    attr_accessor :usage

    # Attribute mapping from ruby-style variable name to JSON key.
    def self.attribute_map
      {
        :'ca_chain' => :'ca_chain',
        :'certificate' => :'certificate',
        :'crl_distribution_points' => :'crl_distribution_points',
        :'delta_crl_distribution_points' => :'delta_crl_distribution_points',
        :'enable_aia_url_templating' => :'enable_aia_url_templating',
        :'issuer_id' => :'issuer_id',
        :'issuer_name' => :'issuer_name',
        :'issuing_certificates' => :'issuing_certificates',
        :'key_id' => :'key_id',
        :'leaf_not_after_behavior' => :'leaf_not_after_behavior',
        :'manual_chain' => :'manual_chain',
        :'ocsp_servers' => :'ocsp_servers',
        :'revocation_signature_algorithm' => :'revocation_signature_algorithm',
        :'revocation_time' => :'revocation_time',
        :'revocation_time_rfc3339' => :'revocation_time_rfc3339',
        :'revoked' => :'revoked',
        :'usage' => :'usage'
      }
    end

    # Returns all the JSON keys this model knows about
    def self.acceptable_attributes
      attribute_map.values
    end

    # Attribute type mapping.
    def self.openapi_types
      {
        :'ca_chain' => :'Array<String>',
        :'certificate' => :'String',
        :'crl_distribution_points' => :'Array<String>',
        :'delta_crl_distribution_points' => :'Array<String>',
        :'enable_aia_url_templating' => :'Boolean',
        :'issuer_id' => :'String',
        :'issuer_name' => :'String',
        :'issuing_certificates' => :'Array<String>',
        :'key_id' => :'String',
        :'leaf_not_after_behavior' => :'String',
        :'manual_chain' => :'Array<String>',
        :'ocsp_servers' => :'Array<String>',
        :'revocation_signature_algorithm' => :'String',
        :'revocation_time' => :'Integer',
        :'revocation_time_rfc3339' => :'String',
        :'revoked' => :'Boolean',
        :'usage' => :'String'
      }
    end

    # List of attributes with nullable: true
    def self.openapi_nullable
      Set.new([
      ])
    end

    # Initializes the object
    # @param [Hash] attributes Model attributes in the form of hash
    def initialize(attributes = {})
      if (!attributes.is_a?(Hash))
        fail ArgumentError, "The input argument (attributes) must be a hash in `OpenbaoClient::PkiPatchIssuerResponse` initialize method"
      end

      # check to see if the attribute exists and convert string to symbol for hash key
      attributes = attributes.each_with_object({}) { |(k, v), h|
        if (!self.class.attribute_map.key?(k.to_sym))
          fail ArgumentError, "`#{k}` is not a valid attribute in `OpenbaoClient::PkiPatchIssuerResponse`. Please check the name to make sure it's valid. List of attributes: " + self.class.attribute_map.keys.inspect
        end
        h[k.to_sym] = v
      }

      if attributes.key?(:'ca_chain')
        if (value = attributes[:'ca_chain']).is_a?(Array)
          self.ca_chain = value
        end
      end

      if attributes.key?(:'certificate')
        self.certificate = attributes[:'certificate']
      end

      if attributes.key?(:'crl_distribution_points')
        if (value = attributes[:'crl_distribution_points']).is_a?(Array)
          self.crl_distribution_points = value
        end
      end

      if attributes.key?(:'delta_crl_distribution_points')
        if (value = attributes[:'delta_crl_distribution_points']).is_a?(Array)
          self.delta_crl_distribution_points = value
        end
      end

      if attributes.key?(:'enable_aia_url_templating')
        self.enable_aia_url_templating = attributes[:'enable_aia_url_templating']
      end

      if attributes.key?(:'issuer_id')
        self.issuer_id = attributes[:'issuer_id']
      end

      if attributes.key?(:'issuer_name')
        self.issuer_name = attributes[:'issuer_name']
      end

      if attributes.key?(:'issuing_certificates')
        if (value = attributes[:'issuing_certificates']).is_a?(Array)
          self.issuing_certificates = value
        end
      end

      if attributes.key?(:'key_id')
        self.key_id = attributes[:'key_id']
      end

      if attributes.key?(:'leaf_not_after_behavior')
        self.leaf_not_after_behavior = attributes[:'leaf_not_after_behavior']
      end

      if attributes.key?(:'manual_chain')
        if (value = attributes[:'manual_chain']).is_a?(Array)
          self.manual_chain = value
        end
      end

      if attributes.key?(:'ocsp_servers')
        if (value = attributes[:'ocsp_servers']).is_a?(Array)
          self.ocsp_servers = value
        end
      end

      if attributes.key?(:'revocation_signature_algorithm')
        self.revocation_signature_algorithm = attributes[:'revocation_signature_algorithm']
      end

      if attributes.key?(:'revocation_time')
        self.revocation_time = attributes[:'revocation_time']
      end

      if attributes.key?(:'revocation_time_rfc3339')
        self.revocation_time_rfc3339 = attributes[:'revocation_time_rfc3339']
      end

      if attributes.key?(:'revoked')
        self.revoked = attributes[:'revoked']
      end

      if attributes.key?(:'usage')
        self.usage = attributes[:'usage']
      end
    end

    # Show invalid properties with the reasons. Usually used together with valid?
    # @return Array for valid properties with the reasons
    def list_invalid_properties
      warn '[DEPRECATED] the `list_invalid_properties` method is obsolete'
      invalid_properties = Array.new
      invalid_properties
    end

    # Check to see if the all the properties in the model are valid
    # @return true if the model is valid
    def valid?
      warn '[DEPRECATED] the `valid?` method is obsolete'
      true
    end

    # Checks equality by comparing each attribute.
    # @param [Object] Object to be compared
    def ==(o)
      return true if self.equal?(o)
      self.class == o.class &&
          ca_chain == o.ca_chain &&
          certificate == o.certificate &&
          crl_distribution_points == o.crl_distribution_points &&
          delta_crl_distribution_points == o.delta_crl_distribution_points &&
          enable_aia_url_templating == o.enable_aia_url_templating &&
          issuer_id == o.issuer_id &&
          issuer_name == o.issuer_name &&
          issuing_certificates == o.issuing_certificates &&
          key_id == o.key_id &&
          leaf_not_after_behavior == o.leaf_not_after_behavior &&
          manual_chain == o.manual_chain &&
          ocsp_servers == o.ocsp_servers &&
          revocation_signature_algorithm == o.revocation_signature_algorithm &&
          revocation_time == o.revocation_time &&
          revocation_time_rfc3339 == o.revocation_time_rfc3339 &&
          revoked == o.revoked &&
          usage == o.usage
    end

    # @see the `==` method
    # @param [Object] Object to be compared
    def eql?(o)
      self == o
    end

    # Calculates hash code according to all attributes.
    # @return [Integer] Hash code
    def hash
      [ca_chain, certificate, crl_distribution_points, delta_crl_distribution_points, enable_aia_url_templating, issuer_id, issuer_name, issuing_certificates, key_id, leaf_not_after_behavior, manual_chain, ocsp_servers, revocation_signature_algorithm, revocation_time, revocation_time_rfc3339, revoked, usage].hash
    end

    # Builds the object from hash
    # @param [Hash] attributes Model attributes in the form of hash
    # @return [Object] Returns the model itself
    def self.build_from_hash(attributes)
      return nil unless attributes.is_a?(Hash)
      attributes = attributes.transform_keys(&:to_sym)
      transformed_hash = {}
      openapi_types.each_pair do |key, type|
        if attributes.key?(attribute_map[key]) && attributes[attribute_map[key]].nil?
          transformed_hash["#{key}"] = nil
        elsif type =~ /\AArray<(.*)>/i
          # check to ensure the input is an array given that the attribute
          # is documented as an array but the input is not
          if attributes[attribute_map[key]].is_a?(Array)
            transformed_hash["#{key}"] = attributes[attribute_map[key]].map { |v| _deserialize($1, v) }
          end
        elsif !attributes[attribute_map[key]].nil?
          transformed_hash["#{key}"] = _deserialize(type, attributes[attribute_map[key]])
        end
      end
      new(transformed_hash)
    end

    # Deserializes the data based on type
    # @param string type Data type
    # @param string value Value to be deserialized
    # @return [Object] Deserialized data
    def self._deserialize(type, value)
      case type.to_sym
      when :Time
        Time.parse(value)
      when :Date
        Date.parse(value)
      when :String
        value.to_s
      when :Integer
        value.to_i
      when :Float
        value.to_f
      when :Boolean
        if value.to_s =~ /\A(true|t|yes|y|1)\z/i
          true
        else
          false
        end
      when :Object
        # generic object (usually a Hash), return directly
        value
      when /\AArray<(?<inner_type>.+)>\z/
        inner_type = Regexp.last_match[:inner_type]
        value.map { |v| _deserialize(inner_type, v) }
      when /\AHash<(?<k_type>.+?), (?<v_type>.+)>\z/
        k_type = Regexp.last_match[:k_type]
        v_type = Regexp.last_match[:v_type]
        {}.tap do |hash|
          value.each do |k, v|
            hash[_deserialize(k_type, k)] = _deserialize(v_type, v)
          end
        end
      else # model
        # models (e.g. Pet) or oneOf
        klass = OpenbaoClient.const_get(type)
        klass.respond_to?(:openapi_any_of) || klass.respond_to?(:openapi_one_of) ? klass.build(value) : klass.build_from_hash(value)
      end
    end

    # Returns the string representation of the object
    # @return [String] String presentation of the object
    def to_s
      to_hash.to_s
    end

    # to_body is an alias to to_hash (backward compatibility)
    # @return [Hash] Returns the object in the form of hash
    def to_body
      to_hash
    end

    # Returns the object in the form of hash
    # @return [Hash] Returns the object in the form of hash
    def to_hash
      hash = {}
      self.class.attribute_map.each_pair do |attr, param|
        value = self.send(attr)
        if value.nil?
          is_nullable = self.class.openapi_nullable.include?(attr)
          next if !is_nullable || (is_nullable && !instance_variable_defined?(:"@#{attr}"))
        end

        hash[param] = _to_hash(value)
      end
      hash
    end

    # Outputs non-array value in the form of hash
    # For object, use to_hash. Otherwise, just return the value
    # @param [Object] value Any valid value
    # @return [Hash] Returns the value in the form of hash
    def _to_hash(value)
      if value.is_a?(Array)
        value.compact.map { |v| _to_hash(v) }
      elsif value.is_a?(Hash)
        {}.tap do |hash|
          value.each { |k, v| hash[k] = _to_hash(v) }
        end
      elsif value.respond_to? :to_hash
        value.to_hash
      else
        value
      end
    end

  end

end
