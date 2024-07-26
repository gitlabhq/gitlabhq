# frozen_string_literal: true

module DeployTokenMethods
  def create_deploy_token_for(entity, current_user, params)
    entity_name = entity.class.name.downcase
    params[:deploy_token_type] = DeployToken.deploy_token_types["#{entity_name}_type".to_sym]
    params["#{entity_name}_id".to_sym] = entity.id

    entity.deploy_tokens.create(params) do |deploy_token|
      deploy_token.username = params[:username].presence
      deploy_token.creator_id = current_user.id
    end
  end

  def destroy_deploy_token(entity, params)
    deploy_token = entity.deploy_tokens.find(params[:token_id])

    deploy_token.destroy
  end

  def create_deploy_token_payload_for(deploy_token)
    if deploy_token.persisted?
      success(deploy_token: deploy_token, http_status: :created)
    else
      error(deploy_token.errors.full_messages.to_sentence, :bad_request, pass_back: { deploy_token: deploy_token })
    end
  end
end
