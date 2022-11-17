# frozen_string_literal: true

module Pajamas
  class AvatarComponent < Pajamas::Component
    include Gitlab::Utils::StrongMemoize

    # @param record [User, Project, Group]
    # @param alt [String] text for the alt tag
    # @param class [String] custom CSS class(es)
    # @param size [Integer] size in pixel
    # @param [Hash] avatar_options
    def initialize(record, alt: nil, class: "", size: 64, avatar_options: {})
      @record = record
      @alt = alt
      @class = binding.local_variable_get(:class)
      @size = filter_attribute(size.to_i, SIZE_OPTIONS, default: 64)
      @avatar_options = avatar_options
    end

    SIZE_OPTIONS = [16, 24, 32, 48, 64, 96].freeze

    private

    def avatar_classes
      classes = ["gl-avatar", "gl-avatar-s#{@size}", @class]
      classes.push("gl-avatar-circle") if @record.is_a?(User)

      unless src
        classes.push("gl-avatar-identicon")
        classes.push("gl-avatar-identicon-bg#{((@record.id || 0) % 7) + 1}")
      end

      classes.join(' ')
    end

    def src
      strong_memoize(:src) do
        if @record.is_a?(User)
          # Users show a gravatar instead of an identicon. Also avatars of
          # blocked users are only shown if the current_user is an admin.
          # To not duplicate this logic, we are using existing helpers here.
          current_user = begin
            helpers.current_user
          rescue StandardError
            nil
          end
          helpers.avatar_icon_for_user(@record, @size, current_user: current_user)
        elsif @record.try(:avatar_url)
          "#{@record.avatar_url}?width=#{@size}"
        end
      end
    end

    def srcset
      return unless src

      retina_src = src.gsub(/(?<=width=)#{@size}+/, (@size * 2).to_s)
      "#{src} 1x, #{retina_src} 2x"
    end

    def alt
      @alt || @record.name
    end

    def initial
      @record.name[0, 1].upcase
    end
  end
end
