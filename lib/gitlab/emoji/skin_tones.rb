# frozen_string_literal: true

module Gitlab
  module Emoji
    # Which emoji is a skin tone variant of which base. Names cannot tell
    # (`thumbsup_tone3` vs `artist_medium_skin_tone`), so the mapping is built
    # from codepoints: strip the tone modifiers and the variation selector and
    # the remaining glyph is the base.
    module SkinTones
      MODIFIERS = (0x1F3FB..0x1F3FF)
      VARIATION_SELECTOR = 0xFE0F
      TONES = 5

      extend self

      # @return [Hash{String => Array<String>}] base name => variant names, tone 1 (light) to 5 (dark)
      def variants_by_base
        mapping[:variants]
      end

      # Two-person emoji whose people have different tones, such as a handshake
      # with a light and a dark hand. They have no single tone, so they are listed
      # instead of mapped to a base.
      # @return [Array<String>]
      def mixed_tone_names
        mapping[:mixed]
      end

      # Single-tone variants whose base has no name of its own because the gem
      # registers that name twice: `man_in_tuxedo_medium_skin_tone` is the man,
      # but `man_in_tuxedo` resolves to the person. Listed so consumers can treat
      # them as variants rather than as plain emoji.
      # @return [Array<String>]
      def unmapped_names
        mapping[:unmapped]
      end

      def base_name(name)
        base_by_variant.fetch(name, name)
      end

      def variants_for(name)
        variants_by_base.fetch(base_name(name), [])
      end

      # Shape written to fixtures/emojis/skin_tones.json
      def to_h
        {
          'variants' => variants_by_base.sort.to_h,
          'mixed' => mixed_tone_names.sort,
          'unmapped' => unmapped_names.sort
        }
      end

      private

      def mapping
        @mapping ||= build
      end

      def base_by_variant
        @base_by_variant ||= variants_by_base.each_with_object({}) do |(base, variants), lookup|
          variants.each { |variant| lookup[variant] = base }
        end.freeze
      end

      # The result is memoized for the life of the process, so it is frozen to
      # keep a caller from corrupting it for every later request.
      def build
        bases_by_glyph = {}
        toned = []

        canonical_characters.each do |character|
          tones = tone_indexes(character.codepoints)

          if tones.empty?
            bases_by_glyph[normalize(character.codepoints)] ||= character.name
          else
            toned << [character, tones]
          end
        end

        variants = Hash.new { |hash, base| hash[base] = Array.new(TONES) }
        mixed = []
        unmapped = []

        toned.each do |character, tones|
          if tones.uniq.size > 1
            mixed << character.name
            next
          end

          glyph = normalize(character.codepoints)
          next if glyph.empty? # the bare modifiers `tone1`..`tone5`

          base = bases_by_glyph[glyph]
          unless base
            unmapped << character.name
            next
          end

          variants[base][tones.first - 1] = character.name
        end

        {
          variants: variants.select { |_, names| names.none?(&:nil?) }.transform_values(&:freeze).freeze,
          mixed: mixed.freeze,
          unmapped: unmapped.freeze
        }.freeze
      end

      # A few names are registered twice (`man_in_tuxedo` is both the person and
      # the man in a tuxedo); keep the one `find_by_alpha_code` returns so the
      # mapping agrees with the rest of the backend.
      def canonical_characters
        TanukiEmoji.index.all.select do |character|
          TanukiEmoji.find_by_alpha_code(character.name).equal?(character)
        end
      end

      def tone_indexes(glyph)
        glyph.codepoints.select { |codepoint| MODIFIERS.cover?(codepoint) }
                        .map { |codepoint| codepoint - MODIFIERS.begin + 1 }
      end

      def normalize(glyph)
        glyph.codepoints
             .reject { |codepoint| MODIFIERS.cover?(codepoint) || codepoint == VARIATION_SELECTOR }
             .pack('U*')
      end
    end
  end
end
