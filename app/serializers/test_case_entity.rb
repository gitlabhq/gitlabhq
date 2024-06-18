# frozen_string_literal: true

class TestCaseEntity < Grape::Entity
  include API::Helpers::RelatedResourcesHelpers

  expose :status, documentation: { type: 'string', example: 'success' }
  expose :name, default: "(No name)",
    documentation: { type: 'string', example: 'Security Reports can create an auto-remediation MR' }
  expose :classname, documentation: { type: 'string', example: 'vulnerability_management_spec' }
  expose :file, documentation: { type: 'string', example: './spec/test_spec.rb' }
  expose :execution_time, documentation: { type: 'integer', example: 180 }
  expose :system_output, documentation: { type: 'string', example: 'Failure/Error: is_expected.to eq(3)' }
  expose :stack_trace, documentation: { type: 'string', example: 'Failure/Error: is_expected.to eq(3)' }
  expose :recent_failures, documentation: { example: { count: 3, base_branch: 'develop' } }
  expose(
    :attachment_url,
    if: ->(*) { can_read_screenshots? },
    documentation: { type: 'string', example: 'http://localhost/namespace1/project1/-/jobs/1/artifacts/file/some/path.png' }
  ) do |test_case|
    expose_url(test_case.attachment_url)
  end

  private

  alias_method :test_case, :object

  def can_read_screenshots?
    test_case.has_attachment?
  end
end
