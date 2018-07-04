require 'spec_helper'

describe EE::Gitlab::Ci::Config do
  let(:config_class) { ::Gitlab::Ci::Config }
  let(:project) { create(:project, :repository) }
  let(:remote_location) { 'https://gitlab.com/gitlab-org/gitlab-ce/blob/1234/.gitlab-ci-1.yml' }
  let(:local_location) { 'ee/spec/fixtures/gitlab/ci/external_files/.gitlab-ci-template-1.yml' }

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

  let(:local_file_content) do
    File.read(Rails.root.join(local_location))
  end

  let(:gitlab_ci_yml) do
    <<~HEREDOC
      include:
        - #{local_location}
        - #{remote_location}

      image: ruby:2.2
    HEREDOC
  end

  let(:config) do
    config_class.new(gitlab_ci_yml, project: project, sha: '12345')
  end

  before do
    WebMock.stub_request(:get, remote_location)
      .to_return(body: remote_file_content)

    allow(project.repository)
      .to receive(:blob_data_at).and_return(local_file_content)
  end

  context 'when the project does not have a valid license' do
    before do
      allow(project).to receive(:feature_available?)
        .with(:external_files_in_gitlab_ci).and_return(false)
    end

    it "should raise a ValidationError" do
      expect { config }.to raise_error(
        ::Gitlab::Ci::YamlProcessor::ValidationError,
        "Your license does not allow to use 'include' keyword in CI/CD configuration file"
      )
    end
  end

  context 'when the project has a valid license' do
    before do
      allow(project).to receive(:feature_available?)
        .with(:external_files_in_gitlab_ci).and_return(true)
    end

    context "when gitlab_ci_yml has valid 'include' defined" do
      before do
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

    describe 'external file version' do
      context 'when external local file SHA is defined' do
        it 'is using a defined value' do
          expect(project.repository).to receive(:blob_data_at)
            .with('eeff1122', local_location)

          config_class.new(gitlab_ci_yml, project: project, sha: 'eeff1122')
        end
      end

      context 'when external local file SHA is not defined' do
        it 'is using latest SHA on the default branch' do
          expect(project.repository).to receive(:root_ref_sha)

          config_class.new(gitlab_ci_yml, project: project)
        end
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
        expect(config.to_hash).to eq({ image: 'ruby:2.2' })
      end
    end

    context "when both external files and gitlab_ci.yml define a dictionary of distinct variables" do
      let(:remote_file_content) do
        <<~HEREDOC
        variables:
          A: 'alpha'
          B: 'beta'
        HEREDOC
      end

      let(:gitlab_ci_yml) do
        <<~HEREDOC
        include:
          - #{remote_location}

        variables:
          C: 'gamma'
          D: 'delta'
        HEREDOC
      end

      it 'should merge the variables dictionaries' do
        expect(config.to_hash).to eq({ variables: { A: 'alpha', B: 'beta', C: 'gamma', D: 'delta' } })
      end
    end

    context "when both external files and gitlab_ci.yml define a dictionary of overlapping variables" do
      let(:remote_file_content) do
        <<~HEREDOC
        variables:
          A: 'alpha'
          B: 'beta'
          C: 'omnicron'
        HEREDOC
      end

      let(:gitlab_ci_yml) do
        <<~HEREDOC
        include:
          - #{remote_location}

        variables:
          C: 'gamma'
          D: 'delta'
        HEREDOC
      end

      it 'later declarations should take precedence' do
        expect(config.to_hash).to eq({ variables: { A: 'alpha', B: 'beta', C: 'gamma', D: 'delta' } })
      end
    end

    context 'when both external files and gitlab_ci.yml define a job' do
      let(:remote_file_content) do
        <<~HEREDOC
        job1:
          script:
          - echo 'hello from remote file'
        HEREDOC
      end

      let(:gitlab_ci_yml) do
        <<~HEREDOC
        include:
          - #{remote_location}

        job1:
          variables:
            VARIABLE_DEFINED_IN_MAIN_FILE: 'some value'
        HEREDOC
      end

      it 'merges the jobs' do
        expect(config.to_hash).to eq({
          job1: {
            script: ["echo 'hello from remote file'"],
            variables: {
              VARIABLE_DEFINED_IN_MAIN_FILE: 'some value'
            }
          }
        })
      end

      context 'when the script key is in both' do
        let(:gitlab_ci_yml) do
          <<~HEREDOC
          include:
            - #{remote_location}

          job1:
            script:
            - echo 'hello from main file'
            variables:
              VARIABLE_DEFINED_IN_MAIN_FILE: 'some value'
          HEREDOC
        end

        it 'uses the script from the gitlab_ci.yml' do
          expect(config.to_hash).to eq({
            job1: {
              script: ["echo 'hello from main file'"],
              variables: {
                VARIABLE_DEFINED_IN_MAIN_FILE: 'some value'
              }
            }
          })
        end
      end
    end
  end
end
