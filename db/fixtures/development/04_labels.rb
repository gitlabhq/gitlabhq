# frozen_string_literal: true

require 'digest/md5'

class Gitlab::Seeder::GroupLabels
  def initialize(group, label_per_group: 10)
    @group = group
    @label_per_group = label_per_group
  end

  def seed!
    @label_per_group.times do
      label_title = FFaker::Product.brand
      Labels::CreateService
        .new(title: label_title, color: "##{Digest::MD5.hexdigest(label_title)[0..5]}")
        .execute(group: @group)
      print '.'
    end
  end
end

class Gitlab::Seeder::ProjectLabels
  def initialize(project, label_per_project: 5)
    @project = project
    @label_per_project = label_per_project
  end

  def seed!
    @label_per_project.times do
      label_title = FFaker::Vehicle.model
      Labels::CreateService
        .new(title: label_title, color: "##{Digest::MD5.hexdigest(label_title)[0..5]}")
        .execute(project: @project)
      print '.'
    end
  end
end

Gitlab::Seeder.quiet do
  puts "\nGenerating group labels"
  Group.all.find_each do |group|
    Gitlab::Seeder::GroupLabels.new(group).seed!
  end

  puts "\nGenerating project labels"
  Project.not_mass_generated.find_each do |project|
    Gitlab::Seeder::ProjectLabels.new(project).seed!
  end
end
