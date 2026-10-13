# frozen_string_literal: true

class AddIamRoleToAiSelfHostedModels < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.5'

  def up
    with_lock_retries do
      add_column :ai_self_hosted_models, :iam_role, :text, if_not_exists: true
    end

    # 2048 is the maximum length of an IAM role ARN, see
    # https://docs.aws.amazon.com/IAM/latest/APIReference/API_Role.html
    add_text_limit :ai_self_hosted_models, :iam_role, 2048
  end

  def down
    with_lock_retries do
      remove_column :ai_self_hosted_models, :iam_role, if_exists: true
    end
  end
end
