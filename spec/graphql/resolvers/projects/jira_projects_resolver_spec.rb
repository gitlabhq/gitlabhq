# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Projects::JiraProjectsResolver, feature_category: :integrations do
  include GraphqlHelpers

  specify do
    expect(described_class).to have_nullable_graphql_type(Types::Projects::Services::JiraProjectType.connection_type)
  end

  describe '#resolve' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project) }

    shared_examples 'no project service access' do
      it 'generates an error' do
        expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) do
          resolve_jira_projects
        end
      end
    end

    context 'when project has no Jira service' do
      let_it_be(:jira_integration) { nil }

      context 'when user is a maintainer' do
        before do
          project.add_maintainer(user)
        end

        it_behaves_like 'no project service access'
      end
    end

    context 'when project has Jira service' do
      let(:jira_integration) { create(:jira_integration, project: project) }

      context 'when user is a developer' do
        before do
          project.add_developer(user)
        end

        it_behaves_like 'no project service access'
      end

      context 'when user is a maintainer' do
        before do
          project.add_maintainer(user)
        end

        context 'when Jira connection is valid' do
          include_context 'Jira projects request context'

          it 'returns Jira projects', :aggregate_failures do
            resolver = resolve_jira_projects
            jira_projects = resolver.items
            project_keys = jira_projects.map(&:key)
            project_names = jira_projects.map(&:name)
            project_ids = jira_projects.map(&:id)

            expect(jira_projects.size).to eq 2
            expect(project_keys).to eq(%w[EX ABC])
            expect(project_names).to eq(%w[Example Alphabetical])
            expect(project_ids).to eq(%w[10000 10001])
            expect(resolver.max_page_size).to eq(2)
          end

          context 'when filtering projects by name' do
            it 'returns Jira projects', :aggregate_failures do
              resolver = resolve_jira_projects({ name: 'ABC' })
              jira_projects = resolver.items
              project_keys = jira_projects.map(&:key)
              project_names = jira_projects.map(&:name)
              project_ids = jira_projects.map(&:id)

              expect(jira_projects.size).to eq 1
              expect(project_keys).to eq(%w[ABC])
              expect(project_names).to eq(%w[Alphabetical])
              expect(project_ids).to eq(%w[10001])
              expect(resolver.max_page_size).to eq(1)
            end
          end
        end

        context 'when Jira connection is not valid' do
          before do
            WebMock.stub_request(:get, 'https://jira.example.com/rest/api/2/project')
              .to_raise(JIRA::HTTPError.new(double(message: 'Bad Request', body: '{"errorMessages":["Some failure."]}')))
          end

          it 'generates a failure error' do
            config_docs_link_url = Rails.application.routes.url_helpers.help_page_path('integration/jira/configure.md')
            docs_link_start = '<a href="%{url}" target="_blank" rel="noopener noreferrer">'.html_safe % { url: config_docs_link_url }
            error_message = 'An error occurred while requesting data from Jira: Some failure. Check your %{docs_link_start}Jira integration configuration</a> and try again.' % { docs_link_start: docs_link_start }

            expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::BaseError, error_message) do
              resolve_jira_projects
            end
          end
        end
      end
    end
  end

  def resolve_jira_projects(args = {}, context = { current_user: user })
    resolve(described_class, obj: jira_integration, args: args, ctx: context)
  end
end
