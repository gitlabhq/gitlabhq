# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiJobTokenAuthLog'], feature_category: :continuous_integration do
  specify { expect(described_class.graphql_name).to eq('CiJobTokenAuthLog') }

  it 'has the correct fields' do
    expected_fields = [:last_authorized_at, :origin_project]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  describe 'query' do
    let_it_be(:origin_project) { create(:project, avatar: avatar_file) }
    let(:scope_field) { subject.dig('data', 'project', 'ciJobTokenAuthLogs') }
    let(:errors_field) { subject['errors'] }
    let(:authorizations_field) { scope_field&.dig('nodes') }
    let(:returned_origin_project_paths) { authorizations_field.pluck('originProject').pluck('path') }
    let(:returned_origin_project_full_paths) { authorizations_field.pluck('originProject').pluck('fullPath') }
    let(:returned_origin_project_avatar_urls) { authorizations_field.pluck('originProject').pluck('avatarUrl') }
    let_it_be(:current_project) { create(:project) }

    let(:authorizations_log) do
      create(
        :ci_job_token_authorization,
        origin_project: origin_project,
        access_project: current_project
      )
    end

    let_it_be(:current_user) { create(:user) }
    let_it_be(:avatar_file) { fixture_file_upload('spec/fixtures/banana_sample.gif', 'image/gif') }

    let(:query) do
      %(
        query {
          project(fullPath: "#{current_project.full_path}") {
            ciJobTokenAuthLogs {
              nodes {
                lastAuthorizedAt
                originProject {
                  path
                  fullPath
                  avatarUrl
                }
              }
            }
          }
        }
      )
    end

    subject { GitlabSchema.execute(query, context: { current_user: current_user }).as_json }

    context 'without access to authorization logs' do
      before do
        current_project.add_member(current_user, :developer)
      end

      it 'returns no authorizations' do
        expect(authorizations_field).to be_nil
        expect(errors_field.first['message']).to include "don't have permission"
      end
    end

    context 'with access to project' do
      before do
        current_project.add_member(current_user, :maintainer)
      end

      context 'when multiple authorizations in the logs' do
        let_it_be(:origin_project_one) { create(:project, avatar: avatar_file) }
        let_it_be(:origin_project_two) { create(:project, avatar: avatar_file) }
        let_it_be(:inaccessible_origin_project_three) { create(:project, avatar: avatar_file) }

        let(:expected_authorizations_paths) do
          [origin_project_one.path, origin_project_two.path,
            inaccessible_origin_project_three.path]
        end

        let(:expected_authorizations_full_paths) do
          [origin_project_one.full_path, origin_project_two.full_path,
            inaccessible_origin_project_three.full_path]
        end

        let(:expected_authorizations_avatar_urls) do
          [origin_project_one.avatar_url(only_path: false), origin_project_two.avatar_url(only_path: false),
            inaccessible_origin_project_three.avatar_url(only_path: false)]
        end

        before do
          origin_project_one.add_member(current_user, :maintainer)
          origin_project_two.add_member(current_user, :maintainer)

          create(:ci_job_token_authorization,
            origin_project: origin_project_one,
            accessed_project: current_project)

          create(:ci_job_token_authorization,
            origin_project: origin_project_two,
            accessed_project: current_project)

          create(:ci_job_token_authorization,
            origin_project: inaccessible_origin_project_three,
            accessed_project: current_project)
        end

        it 'returns authorizations logs on current_project even from inaccessible origin projects' do
          expect(expected_authorizations_paths).to match_array(returned_origin_project_paths)
          expect(expected_authorizations_full_paths).to match_array(returned_origin_project_full_paths)
          expect(expected_authorizations_avatar_urls).to match_array(returned_origin_project_avatar_urls)
        end
      end
    end
  end
end
