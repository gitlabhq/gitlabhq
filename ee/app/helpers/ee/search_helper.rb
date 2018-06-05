module EE
  module SearchHelper
    extend ::Gitlab::Utils::Override

    def search_filter_input_options(type)
      options = super
      options[:data][:'multiple-assignees'] = 'true' if search_multiple_assignees?(type)

      options
    end

    override :find_project_for_result_blob
    def find_project_for_result_blob(result)
      super || ::Project.find(result['_parent'])
    end

    override :parse_search_result
    def parse_search_result(result)
      return super if result.is_a?(Array)

      blob = ::Gitlab::Elastic::SearchResults.parse_search_result(result)

      [blob.filename, blob]
    end

    override :search_blob_title
    def search_blob_title(project, file_name)
      if @project
        file_name
      else
        (project.full_name + ': ' + content_tag(:i, file_name)).html_safe
      end
    end

    private

    def search_multiple_assignees?(type)
      context = @project.presence || @group

      type == :issues &&
        context.feature_available?(:multiple_issue_assignees)
    end
  end
end
