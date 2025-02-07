# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiJobTokenScopeType'], feature_category: :continuous_integration do
  specify { expect(described_class.graphql_name).to eq('CiJobTokenScopeType') }

  it 'has the correct fields' do
    expected_fields = [:projects, :inboundAllowlist, :outboundAllowlist,
      :groupsAllowlist, :inboundAllowlistCount, :groupsAllowlistCount,
      :groupAllowlistAutopopulatedIds, :inboundAllowlistAutopopulatedIds]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  describe 'query' do
    let(:project) do
      create(
        :project,
        ci_outbound_job_token_scope_enabled: true,
        ci_inbound_job_token_scope_enabled: true
      ).tap(&:save!)
    end

    let_it_be(:accessible_group) { create(:group) }
    let_it_be(:inaccessible_group) { create(:group) }

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
              inboundAllowlist {
                nodes {
                  path
                }
              }
              outboundAllowlist {
                nodes {
                  path
                }
              }
              groupsAllowlist {
                nodes {
                  path
                  avatarUrl
                }
              }
            }
          }
        }
      )
    end

    subject { GitlabSchema.execute(query, context: { current_user: current_user }).as_json }

    let(:scope_field) { subject.dig('data', 'project', 'ciJobTokenScope') }
    let(:errors_field) { subject['errors'] }
    let(:projects_field) { scope_field&.dig('projects', 'nodes') }
    let(:outbound_allowlist_field) { scope_field&.dig('outboundAllowlist', 'nodes') }
    let(:inbound_allowlist_field) { scope_field&.dig('inboundAllowlist', 'nodes') }
    let(:returned_project_paths) { projects_field.map { |p| p['path'] } }
    let(:groups_allowlist_field) { scope_field&.dig('groupsAllowlist', 'nodes') }
    let(:returned_groups_paths) { groups_allowlist_field.map { |p| p['path'] } }
    let(:returned_groups_avatar_urls) { groups_allowlist_field.map { |p| p['avatarUrl'] } }
    let(:returned_outbound_paths) { outbound_allowlist_field.map { |p| p['path'] } }
    let(:returned_inbound_paths) { inbound_allowlist_field.map { |p| p['path'] } }

    context 'without access to scope' do
      before do
        project.add_member(current_user, :developer)
      end

      it 'returns no projects' do
        expect(projects_field).to be_nil
        expect(outbound_allowlist_field).to be_nil
        expect(inbound_allowlist_field).to be_nil
        expect(errors_field.first['message']).to include "don't have permission"
      end
    end

    context 'with access to scope' do
      before do
        project.add_member(current_user, :maintainer)
      end

      context 'when multiple projects in the allow lists' do
        include Ci::JobTokenScopeHelpers
        let!(:outbound_allowlist_project) { create_project_in_allowlist(project, direction: :outbound) }
        let!(:inbound_allowlist_project) { create_project_in_allowlist(project, direction: :inbound) }
        let!(:both_allowlists_project) { create_project_in_both_allowlists(project) }

        context 'when linked projects are readable' do
          before do
            outbound_allowlist_project.add_member(current_user, :developer)
            inbound_allowlist_project.add_member(current_user, :developer)
            both_allowlists_project.add_member(current_user, :developer)
          end

          shared_examples 'returns projects' do
            it 'returns readable projects in scope' do
              outbound_paths = [project.path, outbound_allowlist_project.path, both_allowlists_project.path]
              inbound_paths = [project.path, inbound_allowlist_project.path, both_allowlists_project.path]

              expect(returned_project_paths).to contain_exactly(*outbound_paths)
              expect(returned_outbound_paths).to contain_exactly(*outbound_paths)
              expect(returned_inbound_paths).to contain_exactly(*inbound_paths)
            end
          end

          it_behaves_like 'returns projects'

          context 'when job token scope is disabled' do
            before do
              project.ci_cd_settings.update!(job_token_scope_enabled: false)
            end

            it_behaves_like 'returns projects'
          end
        end

        context 'when linked projects are not readable' do
          it 'returns readable projects in scope' do
            expect(returned_project_paths).to contain_exactly(project.path)
            expect(returned_outbound_paths).to contain_exactly(project.path)
          end

          it 'returns even non readable projects in inbound allowlist' do
            expect(returned_inbound_paths).to match_array([project.path, inbound_allowlist_project.path,
              both_allowlists_project.path])
          end
        end

        context 'when groups are in the allow list' do
          before do
            accessible_group.add_member(current_user, :developer)
            allowlist_group(project, inaccessible_group)
            allowlist_group(project, accessible_group)
          end

          it 'returns groups which are accessible and not accessible' do
            expect(returned_groups_paths).to match_array([accessible_group.path, inaccessible_group.path])
            expect(returned_groups_avatar_urls).to match_array([accessible_group.avatar_url,
              inaccessible_group.avatar_url])
          end
        end

        context 'when job token scope is disabled' do
          before do
            project.ci_cd_settings.update!(job_token_scope_enabled: false)
          end

          it 'does not return an error' do
            expect(subject['errors']).to be_nil
          end

          it 'returns readable projects in scope' do
            expect(returned_project_paths).to contain_exactly(project.path)
            expect(returned_outbound_paths).to contain_exactly(project.path)
          end

          it 'returns even non readable projects in inbound allowlist' do
            expect(returned_inbound_paths).to match_array([project.path, inbound_allowlist_project.path,
              both_allowlists_project.path])
          end
        end
      end
    end
  end
end
