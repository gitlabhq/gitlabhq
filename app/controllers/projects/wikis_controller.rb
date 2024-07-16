# frozen_string_literal: true

class Projects::WikisController < Projects::ApplicationController
  include WikiActions

  urgency :low

  alias_method :container, :project

  feature_category :wiki

  before_action do
    push_frontend_feature_flag(:wiki_front_matter_title, project)
  end
end
