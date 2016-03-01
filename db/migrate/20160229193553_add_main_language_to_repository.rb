class AddMainLanguageToRepository < ActiveRecord::Migration
  def change
    add_column :projects, :main_language, :string
  end
end
