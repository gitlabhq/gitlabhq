# frozen_string_literal: true

class PwaController < ApplicationController # rubocop:disable Gitlab/NamespacedClass
  layout 'errors'

  feature_category :navigation
  urgency :low

  skip_before_action :authenticate_user!

  def manifest; end

  def offline; end
end
