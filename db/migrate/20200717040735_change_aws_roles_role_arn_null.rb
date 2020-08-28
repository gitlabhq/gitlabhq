# frozen_string_literal: true

class ChangeAwsRolesRoleArnNull < ActiveRecord::Migration[6.0]
  DOWNTIME = false
  EXAMPLE_ARN = 'arn:aws:iam::000000000000:role/example-role'

  def up
    change_column_null :aws_roles, :role_arn, true
  end

  def down
    # Records may now exist with nulls, so we must fill them with a dummy value
    change_column_null :aws_roles, :role_arn, false, EXAMPLE_ARN
  end
end
