# frozen_string_literal: true

module QA
  RSpec.describe 'Manage', feature_category: :importers do
    describe 'Gitlab migration', :import, :orchestrated, requires_admin: 'creates a user via API' do
      include_context 'with gitlab project migration'
      include Support::API

      let!(:source_member) { create(:user, :set_public_email, api_client: source_admin_api_client) }

      let!(:target_member) do
        create(:user, :set_public_email, api_client: admin_api_client, email: source_member.email)
      end

      def find_group_member(username)
        imported_group.reload!.list_members.find { |usr| usr[:username] == username }
      end

      def find_project_member(username)
        imported_project.reload!.list_members.find { |usr| usr[:username] == username }
      end

      # Query import source users via GraphQL to verify placeholder memberships were created.
      # Bulk import now always uses placeholder user mapping, so imported members appear as
      # Import::SourceUser records with PENDING_REASSIGNMENT status rather than direct memberships.
      def find_import_source_user(source_username)
        query = <<~GQL
          query($fullPath: ID!) {
            namespace(fullPath: $fullPath) {
              importSourceUsers(statuses: [PENDING_REASSIGNMENT]) {
                nodes {
                  sourceUsername
                  sourceName
                  status
                }
              }
            }
          }
        GQL

        request = Runtime::API::Request.new(admin_api_client, '/graphql')
        response = post(
          request.url,
          { query: query, variables: { fullPath: target_sandbox.full_path } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

        nodes = parse_body(response).dig(:data, :namespace, :importSourceUsers, :nodes) || []
        nodes.find { |node| node[:sourceUsername] == source_username }
      end

      context 'with group member' do
        before do
          source_group.add_member(source_member, Resource::Members::AccessLevel::DEVELOPER)
        end

        it(
          'creates a placeholder source user for imported group member',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/354416'
        ) do
          expect_project_import_finished_successfully

          aggregate_failures do
            expect(find_project_member(target_member.username)).to be_nil
            expect(find_group_member(target_member.username)).to be_nil

            expect { find_import_source_user(source_member.username) }
              .to eventually_be_truthy
              .within(max_duration: 30, sleep_interval: 2)
          end
        end
      end

      context 'with project member' do
        before do
          source_project.add_member(source_member, Resource::Members::AccessLevel::DEVELOPER)
        end

        it(
          'creates a placeholder source user for imported project member',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/354417'
        ) do
          expect_project_import_finished_successfully

          aggregate_failures do
            expect(find_group_member(target_member.username)).to be_nil
            expect(find_project_member(target_member.username)).to be_nil

            expect { find_import_source_user(source_member.username) }
              .to eventually_be_truthy
              .within(max_duration: 30, sleep_interval: 2)
          end
        end
      end
    end
  end
end
