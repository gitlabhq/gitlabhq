# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User browses commits', feature_category: :source_code_management do
  include RepoHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository, namespace: user.namespace) }

  before do
    sign_in(user)
  end

  it 'renders commit', :js do
    visit project_commit_path(project, sample_commit.id)

    expect(page).to have_content(sample_commit.message.gsub(/\s+/, ' '))
      .and have_content("Showing #{sample_commit.files_changed_count} changed files")
      .and have_content('Side-by-side')
  end

  it 'fill commit sha when click new tag from commit page', :js do
    dropdown_selector = '[data-testid="commit-options-dropdown"]'
    visit project_commit_path(project, sample_commit.id)
    find(dropdown_selector).click

    page.within(dropdown_selector) do
      click_link 'Tag'
    end

    expect(page).to have_selector("input[value='#{sample_commit.id}']", visible: false)
  end

  it 'renders inline diff button when click side-by-side diff button' do
    visit project_commit_path(project, sample_commit.id)
    find('#parallel-diff-btn').click

    expect(page).to have_content 'Inline'
  end

  it 'renders breadcrumbs on specific commit path' do
    visit project_commits_path(project, project.repository.root_ref + '/files/ruby/regex.rb', limit: 5)

    expect(page).to have_selector('#content-body ul.breadcrumb')
      .and have_selector('#content-body ul.breadcrumb a', count: 4)
  end

  it 'renders diff links to both the previous and current image', :js do
    visit project_commit_path(project, sample_image_commit.id)

    links = page.all('.file-actions a')
    expect(links[0]['href']).to match %r{blob/#{sample_image_commit.old_blob_id}}
    expect(links[1]['href']).to match %r{blob/#{sample_image_commit.new_blob_id}}
  end

  context 'when commit has ci status' do
    let(:pipeline) { create(:ci_pipeline, project: project, sha: sample_commit.id) }

    before do
      project.enable_ci

      create(:ci_build, pipeline: pipeline)
    end

    it 'renders commit ci info' do
      visit project_commit_path(project, sample_commit.id)
      wait_for_requests

      expect(page).to have_selector('.js-commit-box-pipeline-summary')
    end
  end

  context 'primary email' do
    it 'finds a commit by a primary email' do
      user = create(:user, email: 'dmitriy.zaporozhets@gmail.com')

      visit(project_commit_path(project, sample_commit.id))

      check_author_link(sample_commit.author_email, user)
    end
  end

  context 'secondary email' do
    let(:user) { create(:user) }

    it 'finds a commit by a secondary email' do
      create(:email, :confirmed, user: user, email: 'dmitriy.zaporozhets@gmail.com')

      visit(project_commit_path(project, sample_commit.parent_id))

      check_author_link(sample_commit.author_email, user)
    end

    it 'links to an unverified e-mail address instead of the user' do
      create(:email, user: user, email: 'dmitriy.zaporozhets@gmail.com')

      visit(project_commit_path(project, sample_commit.parent_id))

      check_author_email(sample_commit.author_email)
    end
  end

  context 'when the blob does not exist' do
    let(:commit) { create(:commit, project: project) }

    it 'renders successfully', :js do
      allow_next_instance_of(Gitlab::Diff::File) do |instance|
        allow(instance).to receive(:blob).and_return(nil)
      end
      allow_next_instance_of(Gitlab::Diff::File) do |instance|
        allow(instance).to receive(:binary?).and_return(true)
      end

      visit(project_commit_path(project, commit))

      click_button '2 changed files'

      expect(find_by_testid('diff-stats-dropdown')).to have_content('files/ruby/popen.rb')
    end
  end

  describe 'commits list' do
    let(:visit_commits_page) do
      visit project_commits_path(project, project.repository.root_ref, limit: 5)
    end

    it 'searches commit', :js do
      visit_commits_page
      fill_in 'commits-search', with: 'submodules'

      expect(page).to have_content 'More submodules'
      expect(page).not_to have_content 'Change some files'
    end

    it 'renders commits atom feed' do
      visit_commits_page
      click_link('Commits feed')

      commit = project.repository.commit

      expect(response_headers['Content-Type']).to have_content("application/atom+xml")
      expect(body).to have_selector('title', text: "#{project.name}:master commits")
        .and have_selector('author email', text: commit.author_email)
        .and have_selector('entry summary', text: commit.description[0..10].delete("\r\n"))
    end

    context "when commit has a filename with pathspec characters" do
      let(:path) { ':wq' }
      let(:filename) { File.join(path, 'test.txt') }
      let(:ref) { project.repository.root_ref }
      let(:newrev) { project.repository.commit('master').sha }
      let(:short_newrev) { project.repository.commit('master').short_id }
      let(:message) { 'Glob characters' }

      before do
        create_file_in_repo(project, ref, ref, filename, 'Test file', commit_message: message)
        visit project_commits_path(project, "#{ref}/#{path}", limit: 1)
        wait_for_requests
      end

      it 'searches commit', :js do
        expect(page).to have_content(message)

        fill_in 'commits-search', with: 'bogus12345'

        expect(page).to have_content "No results found"

        fill_in 'commits-search', with: 'Glob'

        expect(page).to have_content message
      end
    end

    context 'when a commit links to a confidential issue' do
      let(:confidential_issue) { create(:issue, confidential: true, title: 'Secret issue!', project: project) }

      before do
        project.repository.create_file(
          user,
          'dummy-file',
          'dummy content',
          branch_name: 'feature',
          message: "Linking #{confidential_issue.to_reference}"
        )
      end

      context 'when the user cannot see confidential issues but was cached with a link', :use_clean_rails_memory_store_fragment_caching do
        it 'does not render the confidential issue' do
          visit project_commits_path(project, 'feature')
          sign_in(create(:user))
          visit project_commits_path(project, 'feature')

          expect(page).not_to have_link(href: project_issue_path(project, confidential_issue))
        end
      end
    end

    context 'master branch', :js do
      before do
        visit_commits_page
      end

      it 'renders project commits' do
        commit = project.repository.commit

        expect(page).to have_content(project.name)
          .and have_content(commit.message[0..20])
          .and have_content(commit.short_id)
      end

      it 'does not render create merge request button' do
        expect(page).not_to have_link 'Create merge request'
      end

      it 'shows ref switcher with correct text', :js do
        expect(find('.ref-selector')).to have_text('master')
      end

      context 'when click the compare tab' do
        before do
          wait_for_requests
          click_link('Compare')
        end

        it 'does not render create merge request button', :js do
          expect(page).not_to have_link 'Create merge request'
        end
      end
    end

    context 'feature branch', :js do
      let(:visit_commits_page) do
        visit project_commits_path(project)

        find('.ref-selector').click
        wait_for_requests

        page.within('.ref-selector') do
          fill_in 'Search by Git revision', with: 'feature'
          wait_for_requests
          find('li', text: 'feature', match: :prefer_exact).click
        end
      end

      context 'when project does not have open merge requests' do
        before do
          visit_commits_page
        end

        it 'shows ref switcher with correct text' do
          expect(find('.ref-selector')).to have_text('feature')
        end

        it 'renders project commits' do
          commit = project.repository.commit('0b4bc9a')

          expect(page).to have_content(project.name)
            .and have_content(commit.message[0..12])
            .and have_content(commit.short_id)
        end

        it 'renders create merge request button' do
          expect(page).to have_link 'Create merge request'
        end

        context 'when click the compare tab' do
          before do
            wait_for_requests
            click_link('Compare')
          end

          it 'renders create merge request button', :js do
            expect(page).to have_link 'Create merge request'
          end
        end
      end

      context 'when project have open merge request' do
        let!(:merge_request) do
          create(
            :merge_request,
            title: 'Feature',
            source_project: project,
            source_branch: 'feature',
            target_branch: 'master',
            author: project.users.first
          )
        end

        before do
          visit_commits_page
        end

        it 'renders project commits' do
          commit = project.repository.commit('0b4bc9a')

          expect(page).to have_content(project.name)
            .and have_content(commit.message[0..12])
            .and have_content(commit.short_id)
        end

        it 'renders button to the merge request' do
          expect(page).not_to have_link 'Create merge request'
          expect(page).to have_link 'View open merge request', href: project_merge_request_path(project, merge_request)
        end

        context 'when click the compare tab' do
          before do
            wait_for_requests
            click_link('Compare')
          end

          it 'renders button to the merge request', :js do
            expect(page).not_to have_link 'Create merge request'
            expect(page).to have_link 'View open merge request', href: project_merge_request_path(project, merge_request)
          end
        end
      end
    end
  end
end

private

def check_author_link(email, author)
  author_link = find('.commit-author-link')

  expect(author_link['href']).to eq(user_path(author))
  expect(find('.commit-author-name').text).to eq(author.name)
end

def check_author_email(email)
  author_link = find('.commit-author-link')

  expect(author_link['href']).to eq("mailto:#{email}")
end
