require 'spec_helper'

describe EE::Gitlab::Ci::Config do
  let(:project) { create(:project, :repository) }
  let(:remote_location) { 'https://gitlab.com/gitlab-org/gitlab-ce/blob/1234/.gitlab-ci-1.yml' }
  let(:gitlab_ci_yml) do
    <<~HEREDOC
    include:
      - /ee/spec/fixtures/gitlab/ci/external_files/.gitlab-ci-template-1.yml
      - #{remote_location}

    image: ruby:2.2
    HEREDOC
  end
  let(:config) { ::Gitlab::Ci::Config.new(gitlab_ci_yml, { project: project, sha: '12345' }) }

  context 'when the project does not have a valid license' do
    before do
      allow(project).to receive(:feature_available?).with(:external_files_in_gitlab_ci).and_return(false)
    end

    it "should raise a ValidationError" do
      expect { config }.to raise_error(
        ::Gitlab::Ci::YamlProcessor::ValidationError,
        "Your license does not allow to use 'include' keyword in CI/CD configuration file"
      )
    end
  end

  context 'when the project has a valid license' do
    let(:remote_file_content) do
      <<~HEREDOC
      variables:
        AUTO_DEVOPS_DOMAIN: domain.example.com
        POSTGRES_USER: user
        POSTGRES_PASSWORD: testing-password
        POSTGRES_ENABLED: "true"
        POSTGRES_DB: $CI_ENVIRONMENT_SLUG
      HEREDOC
    end
    let(:local_file_content) {  File.read(Rails.root.join('ee/spec/fixtures/gitlab/ci/external_files/.gitlab-ci-template-1.yml')) }

    before do
      allow(project).to receive(:feature_available?).with(:external_files_in_gitlab_ci).and_return(true)
    end

    context "when gitlab_ci_yml has valid 'include' defined" do
      before do
        allow_any_instance_of(Gitlab::Ci::External::File::Local).to receive(:fetch_local_content).and_return(local_file_content)
        WebMock.stub_request(:get, remote_location).to_return(body: remote_file_content)
      end

      it 'should return a composed hash' do
        before_script_values = [
          "apt-get update -qq && apt-get install -y -qq sqlite3 libsqlite3-dev nodejs", "ruby -v",
          "which ruby",
          "gem install bundler --no-ri --no-rdoc",
          "bundle install --jobs $(nproc)  \"${FLAGS[@]}\""
        ]
        variables = {
          AUTO_DEVOPS_DOMAIN: "domain.example.com",
          POSTGRES_USER: "user",
          POSTGRES_PASSWORD: "testing-password",
          POSTGRES_ENABLED: "true",
          POSTGRES_DB: "$CI_ENVIRONMENT_SLUG"
        }
        composed_hash = {
          before_script: before_script_values,
          image: "ruby:2.2",
          rspec: { script: ["bundle exec rspec"] },
          variables: variables
        }

        expect(config.to_hash).to eq(composed_hash)
      end
    end

    context "when gitlab_ci.yml has invalid 'include' defined"  do
      let(:gitlab_ci_yml) do
        <<~HEREDOC
        include: invalid
        HEREDOC
      end

      it 'raises error YamlProcessor validationError' do
        expect { config }.to raise_error(
          ::Gitlab::Ci::YamlProcessor::ValidationError,
          "Local file 'invalid' is not valid."
        )
      end
    end

    context "when both external files and gitlab_ci.yml defined the same key" do
      let(:gitlab_ci_yml) do
        <<~HEREDOC
        include:
          - #{remote_location}

        image: ruby:2.2
        HEREDOC
      end

      let(:remote_file_content) do
        <<~HEREDOC
        image: php:5-fpm-alpine
        HEREDOC
      end

      it 'should take precedence' do
        WebMock.stub_request(:get, remote_location).to_return(body: remote_file_content)
        expect(config.to_hash).to eq({ image: 'ruby:2.2' })
      end
    end
  end
end
