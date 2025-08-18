# frozen_string_literal: true

module QA
  RSpec.describe 'Create', feature_category: :source_code_management do
    describe 'Create a new project from a template' do
      let(:project) { create(:project, name: 'templated-project', template_name: 'dotnetcore') }

      it 'commits via the api',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/357234' do
        expect do
          create(:commit, project: project, actions: [
            { action: 'update', file_path: '.gitlab-ci.yml', content: 'script' },
            { action: 'create', file_path: 'foo', content: 'bar' }
          ])
        end.not_to raise_exception
      end
    end
  end
end
