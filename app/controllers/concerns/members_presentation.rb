module MembersPresentation
  extend ActiveSupport::Concern

  def present_members(members)
    Gitlab::View::Presenter::Factory.new(
      members,
      current_user: current_user,
      presenter_class: MembersPresenter
    ).fabricate!
  end
end
