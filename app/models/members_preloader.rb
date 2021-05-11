# frozen_string_literal: true

class MembersPreloader
  attr_reader :members

  def initialize(members)
    @members = members
  end

  def preload_all
    ActiveRecord::Associations::Preloader.new.preload(members, :user)
    ActiveRecord::Associations::Preloader.new.preload(members, :source)
    ActiveRecord::Associations::Preloader.new.preload(members, :created_by)
    ActiveRecord::Associations::Preloader.new.preload(members, user: :status)
    ActiveRecord::Associations::Preloader.new.preload(members, user: :u2f_registrations)
    ActiveRecord::Associations::Preloader.new.preload(members, user: :webauthn_registrations) if Feature.enabled?(:webauthn)
  end
end

MembersPreloader.prepend_mod_with('MembersPreloader')
