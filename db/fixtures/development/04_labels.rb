# frozen_string_literal: true

class Gitlab::Seeder::GroupLabels
  def initialize(group, label_per_group: 10)
    @group = group
    @label_per_group = label_per_group
  end

  def seed!
    @label_per_group.times do
      label_title = FFaker::Product.brand
      Labels::CreateService
        .new(title: label_title, color: "#{::Gitlab::Color.color_for(label_title)}")
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
        .new(title: label_title, color: "#{::Gitlab::Color.color_for(label_title)}")
        .execute(project: @project)
      print '.'
    end
  end
end

Gitlab::Seeder.quiet do
  label_per_group = 10
  puts "\nGenerating group labels: #{Group.not_mass_generated.count * label_per_group}"
  Group.not_mass_generated.find_each do |group|
    Gitlab::Seeder::GroupLabels.new(group, label_per_group: label_per_group).seed!
  end

  label_per_project = 5
  puts "\nGenerating project labels: #{Project.not_mass_generated.count * label_per_project}"
  Project.not_mass_generated.find_each do |project|
    Gitlab::Seeder::ProjectLabels.new(project, label_per_project: label_per_project).seed!
  end
end
