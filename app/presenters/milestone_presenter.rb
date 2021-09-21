# frozen_string_literal: true

class MilestonePresenter < Gitlab::View::Presenter::Delegated
  presents ::Milestone, as: :milestone

  def milestone_path
    url_builder.build(milestone, only_path: true)
  end
end
