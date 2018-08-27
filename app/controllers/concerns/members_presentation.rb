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

  # rubocop: disable CodeReuse/ActiveRecord
  def preload_associations(members)
    ActiveRecord::Associations::Preloader.new.preload(members, :user)
    ActiveRecord::Associations::Preloader.new.preload(members, :source)
    ActiveRecord::Associations::Preloader.new.preload(members.map(&:user), :status)
    ActiveRecord::Associations::Preloader.new.preload(members.map(&:user), :u2f_registrations)
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
