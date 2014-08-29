class AddIndexToLabels < ActiveRecord::Migration
  def change
    add_index "labels", :project_id
    add_index "label_links", :label_id
    add_index "label_links", [:target_id, :target_type]
  end
end
