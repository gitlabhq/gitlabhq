# frozen_string_literal: true

class UpdatePackageMaxFileSizePlanLimits < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    # this is intended to be a no-op for GitLab.com
    # 5GB is the value for these columns as of 2020-09-02
    if Gitlab.com?
      update_all_plan_limits('conan_max_file_size', 5.gigabytes)
      update_all_plan_limits('maven_max_file_size', 5.gigabytes)
      update_all_plan_limits('npm_max_file_size', 5.gigabytes)
      update_all_plan_limits('nuget_max_file_size', 5.gigabytes)
      update_all_plan_limits('pypi_max_file_size', 5.gigabytes)
    else
      update_all_plan_limits('conan_max_file_size', 3.gigabytes)
      update_all_plan_limits('maven_max_file_size', 3.gigabytes)
      update_all_plan_limits('npm_max_file_size', 500.megabytes)
      update_all_plan_limits('nuget_max_file_size', 500.megabytes)
      update_all_plan_limits('pypi_max_file_size', 3.gigabytes)
    end
  end

  def down
    update_all_plan_limits('conan_max_file_size', 50.megabytes)
    update_all_plan_limits('maven_max_file_size', 50.megabytes)
    update_all_plan_limits('npm_max_file_size', 50.megabytes)
    update_all_plan_limits('nuget_max_file_size', 50.megabytes)
    update_all_plan_limits('pypi_max_file_size', 50.megabytes)
  end

  private

  def update_all_plan_limits(limit_name, limit_value)
    limit_name_quoted = quote_column_name(limit_name)
    limit_value_quoted = quote(limit_value)

    execute <<~SQL
      UPDATE plan_limits
      SET #{limit_name_quoted} = #{limit_value_quoted};
    SQL
  end
end
