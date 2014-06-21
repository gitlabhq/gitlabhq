class FixNamespaces < ActiveRecord::Migration
  def up
    Namespace.where('name <> path and type is null').each do |namespace|
      namespace.update_attribute(:name, namespace.path)
    end
  end

  def down
  end
end
