# frozen_string_literal: true

class DeleteTemplateServicesDuplicatedByType < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    # Delete service templates with duplicated types. Keep the service
    # template with the lowest `id` because that is the service template used:
    # https://gitlab.com/gitlab-org/gitlab/-/blob/v12.8.1-ee/app/controllers/admin/services_controller.rb#L37
    execute <<~SQL
      DELETE
      FROM services
      WHERE TEMPLATE = TRUE
        AND id NOT IN
          (SELECT MIN(id)
           FROM services
           WHERE TEMPLATE = TRUE
           GROUP BY TYPE);
    SQL
  end

  def down
    # This migration cannot be reversed.
  end
end
