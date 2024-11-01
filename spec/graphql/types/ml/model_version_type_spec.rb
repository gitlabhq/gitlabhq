# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['MlModelVersion'], feature_category: :mlops do
  let_it_be(:model_version) { create(:ml_model_versions, :with_package, description: 'A description') }
  let_it_be(:model_version_markdown) { create(:ml_model_versions, :with_package, description: 'A **description**') }
  let_it_be(:project) { model_version.project }
  let_it_be(:project_markdown) { model_version_markdown.project }
  let_it_be(:current_user) { project.owner }

  let(:query) do
    %(
    query {
          mlModel(id: "gid://gitlab/Ml::Model/#{model_version.model.id}") {
            id
            latestVersion {
              id
              createdAt
              artifactsCount
              author {
                id
                username
                webUrl
                avatarUrl
              }
              version
              packageId
              description
              descriptionHtml
              candidate {
                id
              }
              _links {
                packagePath
                showPath
                importPath
              }
            }
          }
        }
      )
  end

  let(:query_markdown) do
    %(
    query {
          mlModel(id: "gid://gitlab/Ml::Model/#{model_version_markdown.model.id}") {
            id
            latestVersion {
              id
              createdAt
              artifactsCount
              author {
                id
                username
                webUrl
                avatarUrl
              }
              version
              packageId
              description
              descriptionHtml
              candidate {
                id
              }
              _links {
                packagePath
                showPath
                importPath
              }
            }
          }
        }
      )
  end

  let(:data) { GitlabSchema.execute(query, context: { current_user: project.owner }).as_json }

  specify { expect(described_class.description).to eq('Version of a machine learning model') }

  subject(:data_markdown) do
    GitlabSchema.execute(query_markdown, context: {
      current_user: project_markdown.owner
    }).as_json
  end

  it 'includes all fields' do
    expected_fields = %w[id version created_at _links candidate package_id description description_html author]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end

  it 'computes the correct properties' do
    version_data = data.dig('data', 'mlModel', 'latestVersion')

    expect(version_data).to eq({
      'id' => "gid://gitlab/Ml::ModelVersion/#{model_version.id}",
      'version' => model_version.version,
      'createdAt' => model_version.created_at.iso8601,
      'artifactsCount' => model_version.package.package_files.length,
      'author' => {
        'id' => current_user.to_global_id.to_s,
        'username' => current_user.username,
        'webUrl' => "http://localhost/#{current_user.username}",
        'avatarUrl' => current_user.avatar_url
      },
      'description' => 'A description',
      'descriptionHtml' => '<p data-sourcepos="1:1-1:13" dir="auto">A description</p>',
      'packageId' => "gid://gitlab/Packages::Package/#{model_version.package_id}",
      'candidate' => {
        'id' => "gid://gitlab/Ml::Candidate/#{model_version.candidate.id}"
      },
      '_links' => {
        'showPath' => "/#{project.full_path}/-/ml/models/#{model_version.model.id}/versions/#{model_version.id}",
        'packagePath' => "/#{project.full_path}/-/packages/#{model_version.package_id}",
        'importPath' => "/api/v4/projects/#{project.id}/packages/ml_models/#{model_version.id}/files/"
      }
    })
  end

  it 'computes the correct properties with markdown' do
    version_data = data_markdown.dig('data', 'mlModel', 'latestVersion')
    version = model_version_markdown
    user = project_markdown.owner
    expect(version_data).to eq({
      'id' => "gid://gitlab/Ml::ModelVersion/#{version.id}",
      'version' => version.version,
      'createdAt' => version.created_at.iso8601,
      'artifactsCount' => version.package.package_files.length,
      'author' => {
        'id' => user.to_global_id.to_s,
        'username' => user.username,
        'webUrl' => "http://localhost/#{user.username}",
        'avatarUrl' => user.avatar_url
      },
      'description' => 'A **description**',
      'descriptionHtml' =>
        '<p data-sourcepos="1:1-1:17" dir="auto">A <strong data-sourcepos="1:3-1:17">description</strong></p>',
      'packageId' => "gid://gitlab/Packages::Package/#{version.package_id}",
      'candidate' => {
        'id' => "gid://gitlab/Ml::Candidate/#{version.candidate.id}"
      },
      '_links' => {
        'showPath' =>
          "/#{project_markdown.full_path}/-/ml/models/#{version.model.id}/versions/#{version.id}",
        'packagePath' => "/#{project_markdown.full_path}/-/packages/#{version.package_id}",
        'importPath' => "/api/v4/projects/#{project_markdown.id}/packages/ml_models/#{version.id}/files/"
      }
    })
  end

  it 'allows an author to be null' do
    model_version.package.update!(creator: nil)

    version_data = data.dig('data', 'mlModel', 'latestVersion')

    expect(version_data['author']).to be_nil
  end
end
