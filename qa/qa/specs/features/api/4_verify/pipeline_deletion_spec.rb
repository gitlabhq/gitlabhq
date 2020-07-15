# frozen_string_literal: true

module QA
  RSpec.describe 'Verify' do
    include Support::Api

    let(:api_client) { Runtime::API::Client.new(:gitlab) }

    describe 'Pipeline', :runner do
      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'project-with-pipeline'
        end
      end

      let!(:runner) do
        Resource::Runner.fabricate! do |runner|
          runner.project = project
          runner.name = project.name
          runner.tags = [project.name]
        end
      end

      let!(:ci_file) do
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'Add .gitlab-ci.yml'
          commit.add_files(
            [
                {
                    file_path: '.gitlab-ci.yml',
                    content: <<~YAML
                      job1:
                        tags:
                          - #{project.name}
                        script: echo 'OK'
                    YAML
                }
            ]
          )
        end
      end

      let!(:pipeline_id) do
        pipeline_create_request = Runtime::API::Request.new(api_client, "/projects/#{project.id}/pipeline?ref=master")
        JSON.parse(post(pipeline_create_request.url, nil))['id']
      end

      let(:pipeline_data_request) { Runtime::API::Request.new(api_client, "/projects/#{project.id}/pipelines/#{pipeline_id}") }

      after do
        runner.remove_via_api!
      end

      context 'when deleted via API' do
        it 'is not found' do
          delete(pipeline_data_request.url)
          expect(JSON.parse(get(pipeline_data_request.url))['message'].downcase).to have_content('404 not found')
        end
      end
    end
  end
end
