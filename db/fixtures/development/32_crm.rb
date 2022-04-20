# frozen_string_literal: true

class Gitlab::Seeder::Crm
  attr_reader :group, :organizations_per_group, :contacts_per_group

  def initialize(group, organizations_per_group: 10, contacts_per_group: 40)
    @group = group
    @organizations_per_group = organizations_per_group
    @contacts_per_group = contacts_per_group
  end

  def seed!
    organization_ids = []

    organizations_per_group.times do |index|
      organization_ids << ::CustomerRelations::Organization.create!(
        group_id: group.id,
        name: "#{FFaker::Company.name}-#{index}"
      ).id

      print '.'
    end

    contacts_per_group.times do |index|
      first_name = FFaker::Name.first_name
      last_name = FFaker::Name.last_name
      organization_id = index % 3 == 0 ? organization_ids.sample : nil
      ::CustomerRelations::Contact.create!(
        group_id: group.id,
        first_name: first_name,
        last_name: last_name,
        email: "#{first_name}.#{last_name}-#{index}@example.org",
        organization_id: organization_id
      )

      print '.'
    end
  end
end

Gitlab::Seeder.quiet do
  puts "\nGenerating group crm organizations and contacts"

  Group.not_mass_generated.where('parent_id IS NULL').first(10).each do |group|
    Gitlab::Seeder::Crm.new(group).seed!
  end
end
