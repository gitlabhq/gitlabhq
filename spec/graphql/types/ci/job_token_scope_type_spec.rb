# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiJobTokenScopeType'] do
  specify { expect(described_class.graphql_name).to eq('CiJobTokenScopeType') }

  it 'has the correct fields' do
    expected_fields = [:projects]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  describe 'query' do
    let_it_be(:project) { create(:project, ci_job_token_scope_enabled: true).tap(&:save!) }
    let_it_be(:current_user) { create(:user) }

    let(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            ciJobTokenScope {
              projects {
                nodes {
                  path
                }
              }
            }
          }
        }
      )
    end

    subject { GitlabSchema.execute(query, context: { current_user: current_user }).as_json }

    let(:projects_field) { subject.dig('data', 'project', 'ciJobTokenScope', 'projects', 'nodes') }
    let(:returned_project_paths) { projects_field.map { |project| project['path']} }

    context 'with access to scope' do
      before do
        project.add_user(current_user, :maintainer)
      end

      context 'when multiple projects in the allow list' do
        let!(:link) { create(:ci_job_token_project_scope_link, source_project: project) }

        context 'when linked projects are readable' do
          before do
            link.target_project.add_user(current_user, :developer)
          end

          it 'returns readable projects in scope' do
            expect(returned_project_paths).to contain_exactly(project.path, link.target_project.path)
          end
        end

        context 'when linked project is not readable' do
          it 'returns readable projects in scope' do
            expect(returned_project_paths).to contain_exactly(project.path)
          end
        end

        context 'when job token scope is disabled' do
          before do
            project.ci_cd_settings.update!(job_token_scope_enabled: false)
          end

          it 'returns nil' do
            expect(subject.dig('data', 'project', 'ciJobTokenScope')).to be_nil
          end
        end
      end
    end
  end
end
