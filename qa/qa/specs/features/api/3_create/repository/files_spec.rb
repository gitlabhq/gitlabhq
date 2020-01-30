# frozen_string_literal: true

require 'securerandom'

module QA
  describe 'API basics' do
    before(:context) do
      @api_client = Runtime::API::Client.new(:gitlab)
    end

    let(:project_name) { "api-basics-#{SecureRandom.hex(8)}" }
    let(:sanitized_project_path) { CGI.escape("#{Runtime::User.username}/#{project_name}") }

    it 'user creates a project with a file and deletes them afterwards' do
      create_project_request = Runtime::API::Request.new(@api_client, '/projects')
      post create_project_request.url, path: project_name, name: project_name

      expect_status(201)
      expect(json_body).to match(
        a_hash_including(name: project_name, path: project_name)
      )

      create_file_request = Runtime::API::Request.new(@api_client, "/projects/#{sanitized_project_path}/repository/files/README.md")
      post create_file_request.url, branch: 'master', content: 'Hello world', commit_message: 'Add README.md'

      expect_status(201)
      expect(json_body).to match(
        a_hash_including(branch: 'master', file_path: 'README.md')
      )

      get_file_request = Runtime::API::Request.new(@api_client, "/projects/#{sanitized_project_path}/repository/files/README.md", ref: 'master')
      get get_file_request.url

      expect_status(200)
      expect(json_body).to match(
        a_hash_including(
          ref: 'master',
          file_path: 'README.md', file_name: 'README.md',
          encoding: 'base64', content: 'SGVsbG8gd29ybGQ='
        )
      )

      delete_file_request = Runtime::API::Request.new(@api_client, "/projects/#{sanitized_project_path}/repository/files/README.md", branch: 'master', commit_message: 'Remove README.md')
      delete delete_file_request.url

      expect_status(204)

      get_tree_request = Runtime::API::Request.new(@api_client, "/projects/#{sanitized_project_path}/repository/tree")
      get get_tree_request.url

      expect_status(200)
      expect(json_body).to eq([])

      delete_project_request = Runtime::API::Request.new(@api_client, "/projects/#{sanitized_project_path}")
      delete delete_project_request.url

      expect_status(202)
      expect(json_body).to match(
        a_hash_including(message: '202 Accepted')
      )
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

      it 'sets no-cache headers as expected' do
        create_project_request = Runtime::API::Request.new(@api_client, '/projects')
        post create_project_request.url, path: project_name, name: project_name

        create_file_request = Runtime::API::Request.new(@api_client, "/projects/#{sanitized_project_path}/repository/files/test.svg")
        post create_file_request.url, branch: 'master', content: svg_file, commit_message: 'Add test.svg'

        get_file_request = Runtime::API::Request.new(@api_client, "/projects/#{sanitized_project_path}/repository/files/test.svg/raw", ref: 'master')

        3.times do
          response = get get_file_request.url

          # Subsequent responses aren't cached, so headers should match from
          #   request to request, especially a 200 response rather than a 304
          #   (indicating a cached response.) Further, :content_disposition
          #   should include `attachment` for all responses.
          #
          expect(response.headers[:cache_control]).to include("no-store")
          expect(response.headers[:cache_control]).to include("no-cache")
          expect(response.headers[:pragma]).to eq("no-cache")
          expect(response.headers[:expires]).to eq("Fri, 01 Jan 1990 00:00:00 GMT")
          expect(response.headers[:content_disposition]).to include("attachment")
          expect(response.headers[:content_disposition]).not_to include("inline")
          expect(response.headers[:content_type]).to include("image/svg+xml")
        end
      end
    end
  end
end
