# frozen_string_literal: true

module RoadmapsHelper
  def roadmap_layout
    (current_user&.roadmap_layout || params[:layout].presence || EE::User::DEFAULT_ROADMAP_LAYOUT).upcase
  end
end
