require 'spec_helper'

describe "Custom file template classes" do
  files = {
    'Dockerfile/foo.dockerfile' => 'CustomDockerfileTemplate Foo',
    'Dockerfile/bar.dockerfile' => 'CustomDockerfileTemplate Bar',
    'Dockerfile/bad.xyz'        => 'CustomDockerfileTemplate Bad',

    'gitignore/foo.gitignore' => 'CustomGitignoreTemplate Foo',
    'gitignore/bar.gitignore' => 'CustomGitignoreTemplate Bar',
    'gitignore/bad.xyz'       => 'CustomGitignoreTemplate Bad',

    'gitlab-ci/foo.yml' => 'CustomGitlabCiYmlTemplate Foo',
    'gitlab-ci/bar.yml' => 'CustomGitlabCiYmlTemplate Bar',
    'gitlab-ci/bad.xyz' => 'CustomGitlabCiYmlTemplate Bad',

    'LICENSE/foo.txt' => 'CustomLicenseTemplate Foo',
    'LICENSE/bar.txt' => 'CustomLicenseTemplate Bar',
    'LICENSE/bad.xyz' => 'CustomLicenseTemplate Bad',

    'Dockerfile/category/baz.txt' => 'CustomDockerfileTemplate category baz',
    'gitignore/category/baz.txt'  => 'CustomGitignoreTemplate category baz',
    'gitlab-ci/category/baz.yml'  => 'CustomGitlabCiYmlTemplate category baz',
    'LICENSE/category/baz.txt'    => 'CustomLicenseTemplate category baz'
  }

  let(:project) { create(:project, :custom_repo, files: files) }

  [
    ::Gitlab::Template::CustomDockerfileTemplate,
    ::Gitlab::Template::CustomGitignoreTemplate,
    ::Gitlab::Template::CustomGitlabCiYmlTemplate,
    ::Gitlab::Template::CustomLicenseTemplate
  ].each do |template_class|
    describe template_class do
      let(:name) { template_class.name.demodulize }

      describe '.all' do
        it 'returns all valid templates' do
          found = described_class.all(project)

          aggregate_failures do
            expect(found.map(&:name)).to contain_exactly('foo', 'bar')
            expect(found.map(&:category).uniq).to contain_exactly('Custom')
          end
        end
      end

      describe '.find' do
        let(:not_found_error) { ::Gitlab::Template::Finders::RepoTemplateFinder::FileNotFoundError }

        it 'finds a valid template' do
          found = described_class.find('foo', project)

          expect(found.name).to eq('foo')
          expect(found.content).to eq("#{name} Foo")
        end

        it 'sets the category correctly' do
          pending("#{template_class}.find does not set category correctly")
          found = described_class.find('foo', project)

          expect(found.category).to eq('Custom')
        end

        it 'does not find a template with the wrong extension' do
          expect { described_class.find('bad', project) }.to raise_error(not_found_error)
        end

        it 'does not find a template in a subdirectory' do
          expect { described_class.find('baz', project) }.to raise_error(not_found_error)
        end
      end
    end
  end
end
