# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Go::VersionFinder do
  let_it_be(:user) { create :user }
  let_it_be(:project) { create :project_empty_repo, creator: user, path: 'my-go-lib' }

  let(:finder) { described_class.new mod }

  before_all do
    create :go_module_commit, :files,   project: project, tag: 'v1.0.0', files: { 'README.md' => 'Hi' }
    create :go_module_commit, :module,  project: project, tag: 'v1.0.1'
    create :go_module_commit, :package, project: project, tag: 'v1.0.2', path: 'pkg'
    create :go_module_commit, :module,  project: project, tag: 'v1.0.3', name: 'mod'
    create :go_module_commit, :module,  project: project, tag: 'v1.0.4', name: 'bad-mod', url: 'example.com/go-lib'
    create :go_module_commit, :files,   project: project, tag: 'c1',     files: { 'y.go' => "package a\n" }
    create :go_module_commit, :module,  project: project, tag: 'c2',     name: 'v2'
    create :go_module_commit, :files,   project: project, tag: 'v2.0.0', files: { 'v2/x.go' => "package a\n" }
  end

  before do
    stub_feature_flags(go_proxy_disable_gomod_validation: false)
  end

  shared_examples '#execute' do |*expected|
    it "returns #{expected.empty? ? 'nothing' : expected.join(', ')}" do
      actual = finder.execute.map { |x| x.name }
      expect(actual.to_set).to eq(expected.to_set)
    end
  end

  shared_examples '#find with an invalid argument' do |message|
    it "raises an argument exception: #{message}" do
      expect { finder.find(target) }.to raise_error(ArgumentError, message)
    end
  end

  describe '#execute' do
    context 'for the root module' do
      let(:mod) { create :go_module, project: project }

      it_behaves_like '#execute', 'v1.0.1', 'v1.0.2', 'v1.0.3', 'v1.0.4'
    end

    context 'for the package' do
      let(:mod) { create :go_module, project: project, path: 'pkg' }

      it_behaves_like '#execute'
    end

    context 'for the submodule' do
      let(:mod) { create :go_module, project: project, path: 'mod' }

      it_behaves_like '#execute', 'v1.0.3', 'v1.0.4'
    end

    context 'for the root module v2' do
      let(:mod) { create :go_module, project: project, path: 'v2' }

      it_behaves_like '#execute', 'v2.0.0'
    end

    context 'for the bad module' do
      let(:mod) { create :go_module, project: project, path: 'bad-mod' }

      context 'with gomod checking enabled' do
        it_behaves_like '#execute'
      end

      context 'with gomod checking disabled' do
        before do
          stub_feature_flags(go_proxy_disable_gomod_validation: true)
        end

        it_behaves_like '#execute', 'v1.0.4'
      end
    end
  end

  describe '#find' do
    let(:mod) { create :go_module, project: project }

    context 'with a ref' do
      it 'returns a ref version' do
        ref = project.repository.find_branch 'master'
        v = finder.find(ref)
        expect(v.type).to eq(:ref)
        expect(v.ref).to eq(ref)
      end
    end

    context 'with a semver tag' do
      it 'returns a version with a semver' do
        v = finder.find(project.repository.find_tag('v1.0.0'))
        expect(v.major).to eq(1)
        expect(v.minor).to eq(0)
        expect(v.patch).to eq(0)
        expect(v.prerelease).to be_nil
        expect(v.build).to be_nil
      end
    end

    context 'with a semver tag string' do
      it 'returns a version with a semver' do
        v = finder.find('v1.0.1')
        expect(v.major).to eq(1)
        expect(v.minor).to eq(0)
        expect(v.patch).to eq(1)
        expect(v.prerelease).to be_nil
        expect(v.build).to be_nil
      end
    end

    context 'with a commit' do
      it 'retruns a commit version' do
        v = finder.find(project.repository.head_commit)
        expect(v.type).to eq(:commit)
      end
    end

    context 'with a pseudo-version' do
      it 'returns a pseudo version' do
        commit = project.repository.head_commit
        pseudo = "v0.0.0-#{commit.committed_date.strftime('%Y%m%d%H%M%S')}-#{commit.sha[0..11]}"
        v = finder.find(pseudo)
        expect(v.type).to eq(:pseudo)
        expect(v.commit).to eq(commit)
        expect(v.name).to eq(pseudo)
      end
    end

    context 'with a string that is not a semantic version' do
      it 'returns nil' do
        expect(finder.find('not-a-semver')).to be_nil
      end
    end

    context 'with a pseudo-version that does not reference a commit' do
      it_behaves_like '#find with an invalid argument', 'invalid pseudo-version: unknown commit' do
        let(:commit) { project.repository.head_commit }
        let(:target) { "v0.0.0-#{commit.committed_date.strftime('%Y%m%d%H%M%S')}-#{'0' * 12}" }
      end
    end

    context 'with a pseudo-version with a short sha' do
      it_behaves_like '#find with an invalid argument', 'invalid pseudo-version: revision is shorter than canonical' do
        let(:commit) { project.repository.head_commit }
        let(:target) { "v0.0.0-#{commit.committed_date.strftime('%Y%m%d%H%M%S')}-#{commit.sha[0..10]}" }
      end
    end

    context 'with a pseudo-version with an invalid timestamp' do
      it_behaves_like '#find with an invalid argument', 'invalid pseudo-version: does not match version-control timestamp' do
        let(:commit) { project.repository.head_commit }
        let(:target) { "v0.0.0-#{'0' * 14}-#{commit.sha[0..11]}" }
      end
    end
  end
end
