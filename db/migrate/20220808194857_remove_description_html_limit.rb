# frozen_string_literal: true

class RemoveDescriptionHtmlLimit < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    remove_text_limit :namespace_details, :description_html
    remove_text_limit :namespace_details, :description
  end

  def down
    add_text_limit :namespace_details, :description_html, 255
    add_text_limit :namespace_details, :description, 255
  end
end
