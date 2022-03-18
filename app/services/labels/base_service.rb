# frozen_string_literal: true

module Labels
  class BaseService < ::BaseService
    def convert_color_name_to_hex
      ::Gitlab::Color.of(params[:color])
    end
  end
end
