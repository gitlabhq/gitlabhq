# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User edits MR', feature_category: :code_review_workflow do
  include ProjectForksHelper

  shared_examples 'an editable merge request with visible selected labels' do
    it 'updates merge request', :js do
      find('.js-assignee-search').click
      page.within '.dropdown-menu-user' do
        click_link user.name
      end
      expect(find('input[name="merge_request[assignee_ids][]"]', visible: false).value).to match(user.id.to_s)
      page.within '.js-assignee-search' do
        expect(page).to have_content user.name
      end

      find('.js-reviewer-search').click
      page.within '.dropdown-menu-user' do
        click_link user.name
      end
      expect(find('input[name="merge_request[reviewer_ids][]"]', visible: false).value).to match(user.id.to_s)
      page.within '.js-reviewer-search' do
        expect(page).to have_content user.name
      end

      click_button 'Select milestone'
      click_button milestone.title
      expect(find('input[name="merge_request[milestone_id]"]', visible: false).value).to match(milestone.id.to_s)
      expect(page).to have_button milestone.title

      click_button _('Select label')
      wait_for_all_requests
      within_testid('sidebar-labels') do
        click_button label.title
        click_button label2.title
        click_button _('Close')
        wait_for_requests
        within_testid('embedded-labels-list') do
          expect(page).to have_content(label.title)
          expect(page).to have_content(label2.title)
        end
      end

      click_button 'Save changes'

      page.within '.issuable-sidebar' do
        page.within '.assignee' do
          expect(page).to have_content user.name
        end

        page.within '.reviewer' do
          expect(page).to have_content user.name
        end

        page.within '.milestone' do
          expect(page).to have_content milestone.title
        end

        page.within '.labels' do
          expect(page).to have_content label.title
          expect(page).to have_content label2.title
        end
      end
    end

    it 'description has autocomplete', :js do
      find('#merge_request_description').native.send_keys('')
      fill_in 'merge_request_description', with: user.to_reference[0..4]

      page.within('.atwho-view') do
        expect(page).to have_content(user2.name)
      end
    end

    it 'description has quick action autocomplete', :js do
      find('#merge_request_description').native.send_keys('/')

      expect(page).to have_selector('.atwho-container')
    end

    it 'has class js-quick-submit in form' do
      expect(page).to have_selector('.js-quick-submit')
    end

    it 'warns about version conflict', :js do
      merge_request.update!(title: "New title")

      fill_in 'merge_request_title', with: 'bug 345'
      fill_in 'merge_request_description', with: 'bug description'

      click_button _('Save changes')

      expect(page).to have_content(
        format(
          _("Someone edited this %{model_name} at the same time you did. Please check out the %{link_to_model} and make sure your changes will not unintentionally remove theirs."),
          model_name: _('merge request'),
          link_to_model: _('merge request')
        )
      )
    end

    it 'preserves description textarea height', :js do
      long_description = %q(
        Lorem ipsum dolor sit amet, consectetur adipiscing elit.
        Etiam ac ornare ligula, ut tempus arcu.
        Etiam ultricies accumsan dolor vitae faucibus.
        Donec at elit lacus.
        Mauris orci ante, aliquam quis lorem eget, convallis faucibus arcu.
        Aenean at pulvinar lacus.
        Ut viverra quam massa, molestie ornare tortor dignissim a.
        Suspendisse tristique pellentesque tellus, id lacinia metus elementum id.
        Nam tristique, arcu rhoncus faucibus viverra, lacus ipsum sagittis ligula, vitae convallis odio lacus a nibh.
        Ut tincidunt est purus, ac vestibulum augue maximus in.
        Suspendisse vel erat et mi ultricies semper.
        Pellentesque volutpat pellentesque consequat.

        Cras congue nec ligula tristique viverra.
        Curabitur fringilla fringilla fringilla.
        Donec rhoncus dignissim orci ut accumsan.
        Ut rutrum urna a rhoncus varius.
        Maecenas blandit, mauris nec accumsan gravida, augue nibh finibus magna, sed maximus turpis libero nec neque
        Suspendisse at semper est.
        Nunc imperdiet dapibus dui, varius sollicitudin erat luctus non.
        Sed pellentesque ligula eget posuere facilisis.
        Donec dictum commodo volutpat.
        Donec egestas dui ac magna sollicitudin bibendum.
        Vivamus purus neque, ullamcorper ac feugiat et, tempus sit amet metus.
        Praesent quis viverra neque.
        Sed bibendum viverra est, eu aliquam mi ornare vitae.
        Proin et dapibus ipsum.
        Nunc tortor diam, malesuada nec interdum vel, placerat quis justo.
        Ut viverra at erat eu laoreet.

        Pellentesque commodo, diam sit amet dignissim condimentum, tortor justo pretium est,
        non venenatis metus eros ut nunc.
        Etiam ut neque eget sem dapibus aliquam.
        Curabitur vel elit lorem.
        Nulla nec enim elit.
        Sed ut ex id justo facilisis convallis at ac augue.
        Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae;
        Nullam cursus egestas turpis non tristique.
        Suspendisse in erat sem.
        Fusce libero elit, fermentum gravida mauris id, auctor iaculis felis.
        Nullam vulputate tempor laoreet.

        Nam tempor et magna sed convallis.
        Fusce sit amet sollicitudin risus, a ullamcorper lacus.
        Morbi gravida quis sem eget porttitor.
        Donec eu egestas mauris, in elementum tortor.
        Sed eget ex mi.
        Mauris iaculis tortor ut est auctor, nec dignissim quam sagittis.
        Suspendisse vel metus non quam suscipit tincidunt.
        Cras molestie lacus non justo finibus sodales quis vitae erat.
        In a porttitor nisi, id sollicitudin urna.
        Ut at felis tellus.
        Suspendisse potenti.

        Maecenas leo ligula, varius at neque vitae, ornare maximus justo.
        Nullam convallis luctus risus et vulputate.
        Duis suscipit faucibus iaculis.
        Etiam quis tortor faucibus, tristique tellus sit amet, sodales neque.
        Nulla dapibus nisi vel aliquet consequat.
        Etiam faucibus, metus eget condimentum iaculis, enim urna lobortis sem, id efficitur eros sapien nec nisi.
        Aenean ut finibus ex.
      )

      fill_in 'merge_request_description', with: long_description

      height = get_textarea_height
      click_button("Preview")
      click_button("Continue editing")
      new_height = get_textarea_height

      expect(height).to eq(new_height)
    end

    context 'when "Remove source branch" is set' do
      before do
        merge_request.update!(merge_params: { 'force_remove_source_branch' => '1' })
      end

      it 'allows to unselect "Remove source branch"', :js do
        expect(merge_request.merge_params['force_remove_source_branch']).to be_truthy

        uncheck 'Delete source branch when merge request is accepted'

        click_button 'Save changes'

        expect(page).to have_unchecked_field 'remove-source-branch-input'
        expect(page).to have_content 'Delete source branch'
      end
    end
  end

  before do
    stub_licensed_features(multiple_merge_request_assignees: false)
  end

  context 'non-fork merge request' do
    include_context 'merge request edit context'
    it_behaves_like 'an editable merge request with visible selected labels'
  end

  context 'for a forked project' do
    let(:source_project) { fork_project(target_project, nil, repository: true) }

    include_context 'merge request edit context'
    it_behaves_like 'an editable merge request with visible selected labels'
  end
end
