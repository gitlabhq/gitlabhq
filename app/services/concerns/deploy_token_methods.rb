# frozen_string_literal: true

module DeployTokenMethods
  def create_deploy_token_for(entity, params)
    params[:deploy_token_type] = DeployToken.deploy_token_types["#{entity.class.name.downcase}_type".to_sym]

    entity.deploy_tokens.create(params) do |deploy_token|
      deploy_token.username = params[:username].presence
    end
  end

  def destroy_deploy_token(entity, params)
    deploy_token = entity.deploy_tokens.find_by_id!(params[:token_id])

    deploy_token.destroy
  end
end
