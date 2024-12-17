# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    include Support::API

    describe 'API basics', product_group: :source_code do
      let(:test_user) { Runtime::User::Store.test_user }
      let(:api_client) { test_user.api_client }
      let(:project_name) { "api-basics-#{SecureRandom.hex(8)}" }
      let(:sanitized_project_path) { CGI.escape("#{test_user.username}/#{project_name}") }
      let(:file_name) { 'bã®' }
      # this file path deliberately includes a subdirectory which matches the file name to verify file/dir matching logic
      let(:file_path) { CGI.escape("føo/#{file_name}/føo/#{file_name}") }

      it 'user creates a project with a file and deletes them afterwards', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347745' do
        create_project_request = Runtime::API::Request.new(api_client, '/projects')
        response = Support::API.post(create_project_request.url, path: project_name, name: project_name)
        response_body = parse_body(response)

        aggregate_failures do
          expect(response.code).to eq(Support::API::HTTP_STATUS_CREATED)
          expect(response_body).to match(
            a_hash_including(name: project_name, path: project_name)
          )
        end

        default_branch = response_body[:default_branch].to_s.empty? ? Runtime::Env.default_branch : response_body[:default_branch]

        create_file_request = Runtime::API::Request.new(api_client, "/projects/#{sanitized_project_path}/repository/files/#{file_path}")
        response = Support::API.post(create_file_request.url, branch: default_branch, content: 'Hello world', commit_message: 'Add README.md')
        response_body = parse_body(response)

        aggregate_failures do
          expect(response.code).to eq(Support::API::HTTP_STATUS_CREATED)
          expect(response_body).to match(
            a_hash_including(branch: default_branch, file_path: CGI.unescape(file_path))
          )
        end

        get_file_request = Runtime::API::Request.new(api_client, "/projects/#{sanitized_project_path}/repository/files/#{file_path}", ref: default_branch)
        response = Support::API.get(get_file_request.url)
        response_body = parse_body(response)

        aggregate_failures do
          expect(response.code).to eq(Support::API::HTTP_STATUS_OK)
          expect(response_body).to match(
            a_hash_including(
              ref: default_branch,
              file_path: CGI.unescape(file_path), file_name: file_name,
              encoding: 'base64', content: 'SGVsbG8gd29ybGQ='
            )
          )
        end

        delete_file_request = Runtime::API::Request.new(api_client, "/projects/#{sanitized_project_path}/repository/files/#{file_path}", branch: default_branch, commit_message: 'Remove README.md')
        response = Support::API.delete(delete_file_request.url)

        expect(response.code).to eq(Support::API::HTTP_STATUS_NO_CONTENT)

        get_tree_request = Runtime::API::Request.new(api_client, "/projects/#{sanitized_project_path}/repository/tree")
        response = Support::API.get(get_tree_request.url)
        response_body = parse_body(response)

        aggregate_failures do
          expect(response.code).to eq(Support::API::HTTP_STATUS_OK)
          expect(response_body).to eq([])
        end

        delete_project_request = Runtime::API::Request.new(api_client, "/projects/#{sanitized_project_path}")
        response = Support::API.delete(delete_project_request.url)
        response_body = parse_body(response)

        aggregate_failures do
          expect(response.code).to eq(Support::API::HTTP_STATUS_ACCEPTED)
          expect(response_body).to match(
            a_hash_including(message: '202 Accepted')
          )
        end
      end

      describe 'raw file access' do
        let(:svg_file) do
          <<-SVG
          <?xml version="1.0" standalone="no"?>
          <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">

          <svg version="1.1" baseProfile="full" xmlns="http://www.w3.org/2000/svg">
            <polygon id="triangle" points="0,0 0,50 50,0" fill="#009900" stroke="#004400"/>
            <script type="text/javascript">
               alert("surprise");
            </script>
          </svg>
          SVG
        end

        it 'sets no-cache headers as expected',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347746' do
          create_project_request = Runtime::API::Request.new(api_client, '/projects')
          response = Support::API.post(create_project_request.url, path: project_name, name: project_name)
          response_body = parse_body(response)

          default_branch = response_body[:default_branch].to_s.empty? ? Runtime::Env.default_branch : response_body[:default_branch]

          create_file_request = Runtime::API::Request.new(api_client, "/projects/#{sanitized_project_path}/repository/files/test.svg")
          response = Support::API.post(create_file_request.url, branch: default_branch, content: svg_file, commit_message: 'Add test.svg')

          get_file_request = Runtime::API::Request.new(api_client, "/projects/#{sanitized_project_path}/repository/files/test.svg/raw", ref: default_branch)

          3.times do
            response = Support::API.get(get_file_request.url)

            # Subsequent responses aren't cached, so headers should match from
            #   request to request, especially a 200 response rather than a 304
            #   (indicating a cached response.) Further, :content_disposition
            #   should include `attachment` for all responses.
            aggregate_failures do
              expect(response.code).to eq(Support::API::HTTP_STATUS_OK)
              expect(response.headers[:cache_control]).to include("no-store")
              expect(response.headers[:cache_control]).to include("no-cache")
              expect(response.headers[:expires]).to eq("Fri, 01 Jan 1990 00:00:00 GMT")
              expect(response.headers[:content_disposition]).to include("attachment")
              expect(response.headers[:content_disposition]).not_to include("inline")
              expect(response.headers[:content_type]).to include("image/svg+xml")
            end
          end

          delete_project_request = Runtime::API::Request.new(api_client, "/projects/#{sanitized_project_path}")
          response = Support::API.delete(delete_project_request.url)
          response_body = parse_body(response)

          aggregate_failures do
            expect(response.code).to eq(Support::API::HTTP_STATUS_ACCEPTED)
            expect(response_body).to match(
              a_hash_including(message: '202 Accepted')
            )
          end
        end
      end
    end
  end
end
