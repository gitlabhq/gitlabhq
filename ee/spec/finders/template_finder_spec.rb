require 'spec_helper'

describe TemplateFinder do
  using RSpec::Parameterized::TableSyntax

  files = {
    'Dockerfile/custom_dockerfile.dockerfile' => 'Custom Dockerfile',
    'gitignore/custom_gitignore.gitignore'    => 'Custom .gitignore',
    'gitlab-ci/custom_gitlab_ci.yml'          => 'Custom gitlab-ci.yml'
  }

  set(:project) { create(:project, :custom_repo, files: files) }

  describe '#execute' do
    before do
      stub_licensed_features(custom_file_templates: true)
      stub_ee_application_setting(file_template_project: project)
    end

    where(:type, :custom_name, :vendored_name) do
      :dockerfiles    | 'custom_dockerfile' | 'Binary'
      :gitignores     | 'custom_gitignore'  | 'Actionscript'
      :gitlab_ci_ymls | 'custom_gitlab_ci'  | 'Android'
    end

    with_them do
      subject(:result) { described_class.new(type, params).execute }

      context 'specifying name' do
        let(:params) { { name: custom_name } }

        it { is_expected.to have_attributes(name: custom_name) }

        context 'feature is disabled' do
          before do
            stub_licensed_features(custom_file_templates: false)
          end

          it { is_expected.to be_nil }
        end
      end

      context 'not specifying name' do
        let(:params) { {} }

        it { is_expected.to include(have_attributes(name: custom_name)) }
        it { is_expected.to include(have_attributes(name: vendored_name)) }

        context 'feature is disabled' do
          before do
            stub_licensed_features(custom_file_templates: false)
          end

          it { is_expected.not_to include(have_attributes(name: custom_name)) }
          it { is_expected.to include(have_attributes(name: vendored_name)) }
        end
      end
    end
  end
end
