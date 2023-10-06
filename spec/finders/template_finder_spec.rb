# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TemplateFinder do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:template_files) do
    {
      "Dockerfile/project_dockerfiles_template.dockerfile" => "project_dockerfiles_template content",
      "gitignore/project_gitignores_template.gitignore" => "project_gitignores_template content",
      "gitlab-ci/project_gitlab_ci_ymls_template.yml" => "project_gitlab_ci_ymls_template content",
      ".gitlab/issue_templates/project_issues_template.md" => "project_issues_template content",
      ".gitlab/merge_request_templates/project_merge_requests_template.md" => "project_merge_requests_template content"
    }
  end

  RSpec.shared_examples 'fetches predefined vendor templates' do
    where(:type, :vendored_name) do
      :dockerfiles    | 'Binary'
      :gitignores     | 'Actionscript'
      :gitlab_ci_ymls | 'Android'
    end

    with_them do
      it 'returns all vendored templates when no name is specified' do
        expect(result).to include(have_attributes(name: vendored_name))
      end

      context 'with name param' do
        let(:params) { { name: vendored_name } }

        it 'returns only the specified vendored template when a name is specified' do
          expect(result).to have_attributes(name: vendored_name)
        end

        context 'with mistaken name param' do
          let(:params) { { name: 'unknown' } }

          it 'returns nil when an unknown name is specified' do
            expect(result).to be_nil
          end
        end
      end
    end
  end

  RSpec.shared_examples 'no issues and merge requests templates available' do
    context 'with issue and merge request templates' do
      where(:type, :vendored_name) do
        :issues         | nil
        :merge_requests | nil
      end

      with_them do
        context 'when fetching all templates' do
          it 'returns empty array' do
            expect(result).to eq([])
          end
        end

        context 'when looking for specific template by name' do
          let(:params) { { name: 'anything' } }

          it 'raises an error' do
            expect { result }.to raise_exception(Gitlab::Template::Finders::RepoTemplateFinder::FileNotFoundError)
          end
        end
      end
    end
  end

  RSpec.shared_examples 'fetches issues and merge requests templates' do
    where(:type, :template_name) do
      :issues         | 'project_issues_template'
      :merge_requests | 'project_merge_requests_template'
    end

    with_them do
      it 'returns all repository template files for issues and merge requests' do
        expect(result).to include(have_attributes(name: template_name))
      end

      context 'with name param' do
        let(:params) { { name: template_name } }

        it 'returns only the specified vendored template when a name is specified' do
          expect(result).to have_attributes(name: template_name)
        end

        context 'with mistaken name param' do
          let(:params) { { name: 'unknown' } }

          it 'raises an error when an unknown name is specified' do
            expect { result }.to raise_exception(Gitlab::Template::Finders::RepoTemplateFinder::FileNotFoundError)
          end
        end
      end
    end
  end

  describe '#build' do
    let(:project) { build_stubbed(:project) }

    where(:type, :expected_class) do
      :dockerfiles    | described_class
      :gitignores     | described_class
      :gitlab_ci_ymls | described_class
      :licenses | ::LicenseTemplateFinder
      :issues | described_class
      :merge_requests | described_class
    end

    with_them do
      subject(:finder) { described_class.build(type, project) }

      it { is_expected.to be_a(expected_class) }
      it { expect(finder.project).to eq(project) }
    end
  end

  describe '#execute' do
    let_it_be(:project) { nil }

    let(:params) { {} }

    subject(:result) { described_class.new(type, project, params).execute }

    context 'when no project is passed in' do
      it_behaves_like 'fetches predefined vendor templates'
      it_behaves_like 'no issues and merge requests templates available'
    end

    context 'when project has no repository' do
      let_it_be(:project) { create(:project) }

      it_behaves_like 'fetches predefined vendor templates'
      it_behaves_like 'no issues and merge requests templates available'
    end

    context 'when project has a repository' do
      let_it_be(:project) { create(:project, :custom_repo, files: template_files) }

      it_behaves_like 'fetches predefined vendor templates'
      it_behaves_like 'fetches issues and merge requests templates'
    end
  end

  describe '#template_names' do
    let_it_be(:project) { nil }

    let(:params) { {} }

    let(:template_name_struct) { Struct.new(:name, :id, :key, :project_id, keyword_init: true) }

    subject(:result) do
      described_class.new(type, project, params).template_names.values.flatten
        .map { |el| template_name_struct.new(el) }
    end

    where(:type, :vendored_name) do
      :dockerfiles    | 'Binary'
      :gitignores     | 'Actionscript'
      :gitlab_ci_ymls | 'Android'
    end

    with_them do
      context 'when no project is passed in' do
        it 'returns all vendored templates when no name is specified' do
          expect(result).to include(have_attributes(name: vendored_name))
        end
      end

      context 'when project has no repository' do
        let_it_be(:project) { create(:project) }

        it 'returns all vendored templates when no name is specified' do
          expect(result).to include(have_attributes(name: vendored_name))
        end
      end

      context 'when project has a repository' do
        let_it_be(:project) { create(:project, :custom_repo, files: template_files) }

        it 'returns all vendored templates when no name is specified' do
          expect(result).to include(have_attributes(name: vendored_name))
        end
      end

      context 'template names hash keys' do
        it 'has all the expected keys' do
          expect(result.first.to_h.keys).to match_array(%i[id key name project_id])
        end
      end
    end

    where(:type, :template_name) do
      :issues         | 'project_issues_template'
      :merge_requests | 'project_merge_requests_template'
    end

    with_them do
      context 'when no project is passed in' do
        it 'returns all vendored templates when no name is specified' do
          expect(result).to eq([])
        end
      end

      context 'when project has no repository' do
        let_it_be(:project) { create(:project) }

        it 'returns all vendored templates when no name is specified' do
          expect(result).to eq([])
        end
      end

      context 'when project has a repository' do
        let_it_be(:project) { create(:project, :custom_repo, files: template_files) }

        it 'returns all vendored templates when no name is specified' do
          expect(result).to include(have_attributes(name: template_name))
        end

        context 'template names hash keys' do
          it 'has all the expected keys' do
            expect(result.first.to_h.keys).to match_array(%i[id key name project_id])
          end
        end
      end
    end
  end
end
