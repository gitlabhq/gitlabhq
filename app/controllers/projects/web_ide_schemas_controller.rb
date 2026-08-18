# frozen_string_literal: true

class Projects::WebIdeSchemasController < Projects::ApplicationController
  before_action :authenticate_user!

  feature_category :web_ide

  urgency :low

  def show
    return respond_422 unless branch_sha

    result = ::Ide::SchemasConfigService.new(project, current_user, sha: branch_sha,
      filename: params.permit(:filename)[:filename]).execute

    if result[:status] == :success
      render json: result[:schema]
    else
      render json: result, status: :unprocessable_entity
    end
  end

  private

  def branch_sha
    branch = params.permit(:branch)[:branch]
    return unless branch.present?

    project.commit(branch)&.id
  end
end
