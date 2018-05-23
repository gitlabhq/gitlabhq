require 'omniauth'
require 'jwt'

module OmniAuth
  module Strategies
    class JWT
      ClaimInvalid = Class.new(StandardError)

      include OmniAuth::Strategy

      args [:secret]

      option :secret, nil
      option :algorithm, 'HS256'
      option :uid_claim, 'email'
      option :required_claims, %w(name email)
      option :info_map, { name: "name", email: "email" }
      option :auth_url, nil
      option :valid_within, nil

      uid { decoded[options.uid_claim] }

      extra do
        { raw_info: decoded }
      end

      info do
        options.info_map.each_with_object({}) do |(k, v), h|
          h[k.to_s] = decoded[v.to_s]
        end
      end

      def request_phase
        redirect options.auth_url
      end

      def decoded
        @decoded ||= ::JWT.decode(request.params['jwt'], options.secret, options.algorithm).first

        (options.required_claims || []).each do |field|
          raise ClaimInvalid, "Missing required '#{field}' claim" unless @decoded.key?(field.to_s)
        end

        raise ClaimInvalid, "Missing required 'iat' claim" if options.valid_within && !@decoded["iat"]

        if options.valid_within && (Time.now.to_i - @decoded["iat"]).abs > options.valid_within
          raise ClaimInvalid, "'iat' timestamp claim is too skewed from present"
        end

        @decoded
      end

      def callback_phase
        super
      rescue ClaimInvalid => e
        fail! :claim_invalid, e
      end
    end

    class Jwt < JWT; end
  end
end
