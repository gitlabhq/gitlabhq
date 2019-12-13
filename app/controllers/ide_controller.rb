# frozen_string_literal: true

class IdeController < ApplicationController
  layout 'fullscreen'

  def index
  end
end

IdeController.prepend(EE::IdeController)
