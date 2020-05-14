# frozen_string_literal: true

class MembersPreloader
  attr_reader :members

  def initialize(members)
    @members = members
  end

  def preload_all
    ActiveRecord::Associations::Preloader.new.preload(members, :user)
    ActiveRecord::Associations::Preloader.new.preload(members, :source)
    ActiveRecord::Associations::Preloader.new.preload(members.map(&:user), :status)
    ActiveRecord::Associations::Preloader.new.preload(members.map(&:user), :u2f_registrations)
  end
end

MembersPreloader.prepend_if_ee('EE::MembersPreloader')
