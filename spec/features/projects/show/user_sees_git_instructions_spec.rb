# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Show > User sees Git instructions' do
  let_it_be(:user) { create(:user) }

  shared_examples_for 'redirects to the sign in page' do
    it 'redirects to the sign in page' do
      expect(current_path).to eq(new_user_session_path)
    end
  end

  shared_examples_for 'shows details of empty project with no repo' do
    it 'shows Git command line instructions' do
      click_link 'Create empty repository'

      page.within '.empty-wrapper' do
        expect(page).to have_content('Command line instructions')
      end

      expect(page).to have_content("git push -u origin master")
    end
  end

  shared_examples_for 'shows details of empty project' do
    let(:user_has_ssh_key) { false }

    it 'shows details' do
      expect(page).not_to have_content('Git global setup')

      page.all(:css, '.git-empty .clone').each do |element|
        expect(element.text).to include(project.http_url_to_repo)
      end

      expect(page).to have_field('http_project_clone', with: project.http_url_to_repo) unless user_has_ssh_key
    end
  end

  shared_examples_for 'shows details of non empty project' do
    let(:user_has_ssh_key) { false }

    it 'shows details' do
      page.within('.breadcrumbs .breadcrumb-item-text') do
        expect(page).to have_content(project.title)
      end

      expect(page).to have_field('http_project_clone', with: project.http_url_to_repo) unless user_has_ssh_key
    end
  end

  context 'when project is public' do
    context 'when project has no repo' do
      let_it_be(:project) { create(:project, :public) }

      before do
        sign_in(project.owner)
        visit project_path(project)
      end

      include_examples 'shows details of empty project with no repo'
    end

    context ":default_branch_name is specified" do
      let_it_be(:project) { create(:project, :public) }

      before do
        expect(Gitlab::CurrentSettings)
          .to receive(:default_branch_name)
          .at_least(:once)
          .and_return('example_branch')

        sign_in(project.owner)
        visit project_path(project)
      end

      it "recommends default_branch_name instead of master" do
        click_link 'Create empty repository'

        expect(page).to have_content("git push -u origin example_branch")
      end
    end

    context 'when project is empty' do
      let_it_be(:project) { create(:project_empty_repo, :public) }

      context 'when not signed in' do
        before do
          visit(project_path(project))
        end

        include_examples 'shows details of empty project'
      end

      context 'when signed in' do
        before do
          sign_in(user)
        end

        context 'when user does not have ssh keys' do
          before do
            visit(project_path(project))
          end

          include_examples 'shows details of empty project'
        end

        context 'when user has ssh keys' do
          before do
            create(:personal_key, user: user)

            visit(project_path(project))
          end

          include_examples 'shows details of empty project' do
            let(:user_has_ssh_key) { true }
          end
        end
      end
    end

    context 'when project is not empty' do
      let_it_be(:project) { create(:project, :public, :repository) }

      before do
        visit(project_path(project))
      end

      context 'when not signed in' do
        before do
          allow(Gitlab.config.gitlab).to receive(:host).and_return('www.example.com')
        end

        include_examples 'shows details of non empty project'
      end

      context 'when signed in' do
        before do
          sign_in(user)
        end

        context 'when user does not have ssh keys' do
          before do
            visit(project_path(project))
          end

          include_examples 'shows details of non empty project'
        end

        context 'when user has ssh keys' do
          before do
            create(:personal_key, user: user)

            visit(project_path(project))
          end

          include_examples 'shows details of non empty project' do
            let(:user_has_ssh_key) { true }
          end
        end
      end
    end
  end

  context 'when project is internal' do
    let_it_be(:project) { create(:project, :internal, :repository) }

    context 'when not signed in' do
      before do
        visit(project_path(project))
      end

      include_examples 'redirects to the sign in page'
    end

    context 'when signed in' do
      before do
        sign_in(user)

        visit(project_path(project))
      end

      include_examples 'shows details of non empty project'
    end
  end

  context 'when project is private' do
    let_it_be(:project) { create(:project, :private) }

    before do
      visit(project_path(project))
    end

    include_examples 'redirects to the sign in page'
  end
end
