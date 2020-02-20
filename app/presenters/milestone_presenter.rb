# frozen_string_literal: true

class MilestonePresenter < Gitlab::View::Presenter::Delegated
  presents :milestone

  def milestone_path
    url_builder.milestone_path(milestone)
  end

  private

  def url_builder
    @url_builder ||= Gitlab::UrlBuilder.new(milestone)
  end
end
