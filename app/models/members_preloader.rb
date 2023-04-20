# frozen_string_literal: true

class MembersPreloader
  attr_reader :members

  def initialize(members)
    @members = members
  end

  def preload_all
    ActiveRecord::Associations::Preloader.new(
      records: members,
      associations: [
        :source,
        :created_by,
        { user: [:status, :webauthn_registrations] }
      ]
    ).call
  end
end

MembersPreloader.prepend_mod_with('MembersPreloader')
