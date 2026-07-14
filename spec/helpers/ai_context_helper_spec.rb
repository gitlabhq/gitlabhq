# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AiContextHelper, feature_category: :portfolio_management do
  describe '#ai_context_block' do
    context 'when given a project with a repository' do
      # rubocop:disable RSpec/FactoryBot/AvoidCreate -- :repository needs a real Gitaly repo; authorization needs a persisted membership
      let_it_be(:project) { create(:project, :repository) }
      let_it_be(:user) { create(:user, developer_of: project) }
      # rubocop:enable RSpec/FactoryBot/AvoidCreate

      let(:readme_path) { nil }
      let(:contribution_guide) { nil }
      let(:agents_blob) { nil }
      let(:claude_blob) { nil }
      let(:default_branch) { project.default_branch_or_main }

      before do
        allow(helper).to receive(:current_user).and_return(user)

        allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::NullStore.new)

        allow(project.repository).to receive_messages(
          readme_path: readme_path,
          contribution_guide: contribution_guide
        )
        allow(project.repository).to receive(:blob_at)
          .with(default_branch, 'AGENTS.md')
          .and_return(agents_blob)
        allow(project.repository).to receive(:blob_at)
          .with(default_branch, 'CLAUDE.md')
          .and_return(claude_blob)
      end

      subject(:block) { helper.ai_context_block(project) }

      it 'returns a visually-hidden div with project metadata', :aggregate_failures do
        expect(block).to have_css('div.gl-hidden[data-testid="ai-context"]')
        expect(block).to include("Project: #{project.full_path}")
        expect(block).to include("Repository: #{project_url(project)}")
      end

      it 'includes the GitLab AI Context header' do
        expect(block).to include("GitLab AI Context")
      end

      it 'includes the instance line' do
        expect(block).to include("Instance: #{Gitlab.config.gitlab.url}")
      end

      it 'includes a minimal tools section', :aggregate_failures do
        expect(block).to include("Required tooling")
        expect(block).to include("GitLab CLI (glab):")
        expect(block).to include(AiContextHelper::GLAB_CLI_URL)
      end

      context 'when README exists' do
        let(:readme_path) { 'README.md' }

        it 'includes a raw link to the README with a description', :aggregate_failures do
          expect(block).to include("/-/raw/#{default_branch}/README.md — project overview and setup")
          expect(block).to include("READ each of these files and FOLLOW their guidance:")
        end
      end

      context 'when CONTRIBUTING.md exists' do
        let(:contribution_guide) { instance_double(Gitlab::Git::Blob, path: 'CONTRIBUTING.md') }

        it 'includes a raw link to CONTRIBUTING.md with a description' do
          expect(block).to include("/-/raw/#{default_branch}/CONTRIBUTING.md — contribution guidelines")
        end
      end

      context 'when AGENTS.md exists' do
        let(:agents_blob) { instance_double(Blob) }

        it 'includes a raw link to AGENTS.md with a description' do
          expect(block).to include("/-/raw/#{default_branch}/AGENTS.md — AI agent instructions")
        end
      end

      context 'when CLAUDE.md exists' do
        let(:claude_blob) { instance_double(Blob) }

        it 'includes a raw link to CLAUDE.md with a description' do
          expect(block).to include("/-/raw/#{default_branch}/CLAUDE.md — Claude Code instructions")
        end
      end

      context 'when no key files exist' do
        it 'does not include the key files section', :aggregate_failures do
          expect(block).not_to include("READ each of these files")
          expect(block).not_to include("/-/raw/#{default_branch}/CONTRIBUTING.md")
          expect(block).not_to include("/-/raw/#{default_branch}/README.md")
          expect(block).not_to include("/-/raw/#{default_branch}/AGENTS.md")
          expect(block).not_to include("/-/raw/#{default_branch}/CLAUDE.md")
        end
      end

      context 'when the repository has no commits' do
        before do
          allow(project.repository).to receive(:commit).and_return(nil)
        end

        it 'omits the key files section but keeps repository metadata', :aggregate_failures do
          expect(block).not_to include("READ each of these files")
          expect(block).to include("Repository: #{project_url(project)}")
        end
      end

      context 'when multiple key files exist' do
        let(:readme_path) { 'README.md' }
        let(:contribution_guide) { instance_double(Gitlab::Git::Blob, path: 'CONTRIBUTING.md') }
        let(:agents_blob) { instance_double(Blob) }

        it 'lists the key files', :aggregate_failures do
          expect(block).to include("READ each of these files")
          expect(block).to include("CONTRIBUTING.md")
          expect(block).to include("AGENTS.md")
          expect(block).to include("README.md")
        end
      end

      context 'when caching key file lookups', :use_clean_rails_memory_store_caching do
        let(:agents_blob) { instance_double(Blob) }

        before do
          allow(Rails).to receive(:cache).and_call_original
        end

        it 'only queries the repository once across multiple renders' do
          expect(project.repository).to receive(:blob_at)
            .with(default_branch, 'AGENTS.md')
            .once
            .and_return(agents_blob)

          2.times { helper.ai_context_block(project) }
        end

        it 'caches the detected paths keyed on the head commit sha' do
          commit_sha = project.repository.commit.sha

          helper.ai_context_block(project)

          expect(Rails.cache.read(['ai_context_key_files', project.id, commit_sha]))
            .to match_array([['AGENTS.md', 'AI agent instructions']])
        end
      end
    end

    context 'when the project has no repository' do
      # rubocop:disable RSpec/FactoryBot/AvoidCreate -- needs a real project with a real user
      let_it_be(:project) { create(:project) }
      let_it_be(:user) { create(:user, developer_of: project) }
      # rubocop:enable RSpec/FactoryBot/AvoidCreate

      subject(:block) { helper.ai_context_block(project) }

      before do
        allow(helper).to receive(:current_user).and_return(user)
      end

      it 'still renders the context block with project identity', :aggregate_failures do
        expect(block).to have_css('div.gl-hidden[data-testid="ai-context"]')
        expect(block).to include("Project: #{project.full_path}")
      end

      it 'omits repository-specific metadata', :aggregate_failures do
        expect(block).not_to include("Repository:")
        expect(block).not_to include("READ each of these files")
      end

      it 'still includes the instance and tools sections', :aggregate_failures do
        expect(block).to include("Instance: #{Gitlab.config.gitlab.url}")
        expect(block).to include("Required tooling")
      end
    end

    context 'when the user cannot read the code' do
      let_it_be(:project) { create(:project, :repository, :private) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- needs a real repository to exercise the read-code authorization gate

      subject(:block) { helper.ai_context_block(project) }

      before do
        allow(helper).to receive(:current_user).and_return(nil)
      end

      it 'includes the public project identity' do
        expect(block).to include("Project: #{project.full_path}")
      end

      it 'omits repository details and key files', :aggregate_failures do
        expect(block).not_to include("Repository:")
        expect(block).not_to include("READ each of these files")
      end

      it 'does not query the repository for key files' do
        expect(project.repository).not_to receive(:blob_at)
        expect(project.repository).not_to receive(:readme_path)

        block
      end

      it 'still includes the instance and tools sections', :aggregate_failures do
        expect(block).to include("Instance: #{Gitlab.config.gitlab.url}")
        expect(block).to include("Required tooling")
      end
    end

    context 'when given nil' do
      it 'returns nil' do
        expect(helper.ai_context_block(nil)).to be_nil
      end
    end
  end
end
