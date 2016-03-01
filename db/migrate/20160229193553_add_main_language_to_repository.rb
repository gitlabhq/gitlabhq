class AddMainLanguageToRepository < ActiveRecord::Migration
  require 'rugged'
  require 'linguist'

  def up
    add_column :projects, :main_language, :string, default: nil

    Project.all.each do |project|
      unless project.repository.empty?
        language = Linguist::Repository.new(
          project.repository.rugged,
          project.repository.rugged.head.target_id).language
        project.update_attributes(main_language: language)
      end
    end
  end

  def down
    remove_column :projects, :main_language
  end
end
