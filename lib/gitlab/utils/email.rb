# frozen_string_literal: true

module Gitlab
  module Utils
    module Email
      extend self

      # Replaces most visible characters with * to obfuscate an email address
      # deform adds a fix number of * to ensure the address cannot be guessed. Also obfuscates TLD with **
      def obfuscated_email(email, deform: false)
        return email if email.empty?

        masker_class = deform ? Deform : Symmetrical
        masker_class.new(email).masked
      end

      class Masker
        attr_reader :local_part, :sub_domain, :toplevel_domain, :at, :dot

        def initialize(original)
          @original = original
          @local_part, @at, domain = original.rpartition('@')
          @sub_domain, @dot, @toplevel_domain = domain.rpartition('.')

          @at = nil if @at.empty?
          @dot = nil if @dot.empty?
        end

        def masked
          masked = [
            local_part,
            at,
            sub_domain,
            dot,
            toplevel_domain
          ].compact.join('')

          masked = mask(@original, visible_length: 1) if masked == @original

          masked
        end

        private

        def mask(plain, visible_length:, star_length: nil)
          return if plain.empty?
          return plain if visible_length < 0

          plain = enlarge_if_needed(plain, visible_length)

          star_length = plain.length - visible_length if star_length.nil?

          first = plain[0, visible_length]
          stars = '*' * star_length

          "#{first}#{stars}"
        end

        def enlarge_if_needed(string, min)
          string.ljust(min, string.first)
        end
      end

      class Symmetrical < Masker
        def local_part
          mask(@local_part, visible_length: 2)
        end

        def sub_domain
          mask(@sub_domain, visible_length: 1)
        end
      end

      # Implements https://design.gitlab.com/usability/obfuscation#email-addresses
      class Deform < Masker
        def local_part
          mask(@local_part, visible_length: 2, star_length: 5)
        end

        def sub_domain
          mask(@sub_domain, visible_length: 1, star_length: 5)
        end

        def toplevel_domain
          mask(@toplevel_domain, visible_length: 1, star_length: 2)
        end
      end
    end
  end
end
