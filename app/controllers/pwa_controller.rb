# frozen_string_literal: true

class PwaController < ApplicationController # rubocop:disable Gitlab/NamespacedClass
  layout 'errors'

  feature_category :navigation

  skip_before_action :authenticate_user!

  def offline
  end
end
