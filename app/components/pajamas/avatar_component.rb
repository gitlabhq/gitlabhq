# frozen_string_literal: true

module Pajamas
  AvatarEmail = Struct.new(:email) do
    def name
      email
    end
  end
  class AvatarComponent < Pajamas::Component
    include Gitlab::Utils::StrongMemoize

    SIZE_OPTIONS = [16, 24, 32, 48, 64, 96].freeze

    # @param item [User, Project, Group, AvatarEmail, String]
    # @param alt [String] text for the alt attribute
    # @param class [String] custom CSS class(es)
    # @param size [Integer] size in pixel
    # @param [Hash] avatar_options
    def initialize(item, alt: nil, class: "", size: 64, avatar_options: {})
      @item = item
      @alt = alt
      @class = binding.local_variable_get(:class)
      @size = filter_attribute(size.to_i, SIZE_OPTIONS, default: 64)
      @avatar_options = avatar_options
    end

    private

    def avatar_classes
      classes = ["gl-avatar", "gl-avatar-s#{@size}", @class] # rubocop:disable Tailwind/StringInterpolation -- Not a CSS utility class
      if @item.is_a?(User) || @item.is_a?(AvatarEmail)
        classes.push("gl-avatar-circle")
      else
        classes.push("!gl-rounded-base")
      end

      unless src
        classes.push("gl-avatar-identicon")
        classes.push("gl-avatar-identicon-bg#{((@item.id || 0) % 7) + 1}") # rubocop:disable Tailwind/StringInterpolation -- Not a CSS utility class
      end

      classes.join(' ')
    end

    def src
      if @item.is_a?(String)
        @item
      elsif @item.is_a?(User)
        # Users show a gravatar instead of an identicon. Also avatars of
        # blocked users are only shown if the current_user is an admin.
        # To not duplicate this logic, we are using existing helpers here.
        current_user = begin
          helpers.current_user
        rescue StandardError
          nil
        end
        helpers.avatar_icon_for_user(@item, @size, current_user: current_user)
      elsif @item.is_a?(AvatarEmail)
        helpers.avatar_icon_for_email(@item.email, @size)
      elsif @item.try(:avatar_url)
        "#{@item.avatar_url}?width=#{@size}"
      end
    end
    strong_memoize_attr :src

    def srcset
      return unless src

      retina_src = src.gsub(/(?<=width=)#{@size}+/, (@size * 2).to_s)
      "#{src} 1x, #{retina_src} 2x"
    end

    def alt
      @alt || @item.try(:name)
    end

    def initial
      @item.name[0, 1].upcase
    end
  end
end
