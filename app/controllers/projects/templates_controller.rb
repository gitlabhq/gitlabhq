class Projects::TemplatesController < Projects::ApplicationController
  before_action :authenticate_user!, :get_template_class

  def show
    template = @template_type.find(params[:key], project)

    respond_to do |format|
      format.json { render json: template.to_json }
    end
  end

  private

  def get_template_class
    template_types = { issue: Gitlab::Template::IssueTemplate, merge_request: Gitlab::Template::MergeRequestTemplate }.with_indifferent_access
    @template_type = template_types[params[:template_type]]
    render json: [], status: :not_found unless @template_type
  end
end
