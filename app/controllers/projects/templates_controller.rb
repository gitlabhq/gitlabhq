# frozen_string_literal: true

class Projects::TemplatesController < Projects::ApplicationController
  before_action :authenticate_user!
  before_action :authorize_can_read_issuable!
  before_action :get_template_class

  feature_category :source_code_management
  urgency :low, [:names]

  def index
    templates = @template_type.template_subsets(project)

    respond_to do |format|
      format.json { render json: Gitlab::Json.dump(templates) }
    end
  end

  def show
    template = @template_type.find(key_param, project)

    respond_to do |format|
      format.json { render json: Gitlab::Json.dump(template) }
    end
  end

  def names
    respond_to do |format|
      format.json { render json: TemplateFinder.all_template_names(project, template_type_param.to_s.pluralize) }
    end
  end

  private

  # User must have:
  # - `read_merge_request` to see merge request templates, or
  # - `read_issue` to see issue templates
  #
  # Note params[:template_type] has a route constraint to limit it to
  # `merge_request` or `issue`
  def authorize_can_read_issuable!
    action = [:read_, template_type_param].join

    authorize_action!(action)
  end

  def get_template_class
    template_types = { issue: Gitlab::Template::IssueTemplate,
                       merge_request: Gitlab::Template::MergeRequestTemplate }.with_indifferent_access
    @template_type = template_types[template_type_param]
  end

  def template_type_param
    params.permit(:template_type)[:template_type]
  end

  def key_param
    params.permit(:key)[:key]
  end
end
