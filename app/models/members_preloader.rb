# frozen_string_literal: true

class MembersPreloader
  attr_reader :members

  def initialize(members)
    @members = members
  end

  def preload_all
    user_associations = [:status, :u2f_registrations]
    user_associations << :webauthn_registrations if Feature.enabled?(:webauthn)

    ActiveRecord::Associations::Preloader.new(
      records: members,
      associations: [
        :source,
        :created_by,
        { user: user_associations }
      ]
    ).call
  end
end

MembersPreloader.prepend_mod_with('MembersPreloader')
