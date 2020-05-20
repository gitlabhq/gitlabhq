# frozen_string_literal: true

module MembersPresentation
  extend ActiveSupport::Concern

  def present_members(members)
    preload_associations(members)

    Gitlab::View::Presenter::Factory.new(
      members,
      current_user: current_user,
      presenter_class: MembersPresenter
    ).fabricate!
  end

  def preload_associations(members)
    MembersPreloader.new(members).preload_all
  end
end
