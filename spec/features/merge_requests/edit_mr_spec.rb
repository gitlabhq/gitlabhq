require 'spec_helper'

feature 'Edit Merge Request', feature: true do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }
  let(:merge_request) { create(:merge_request, :simple, source_project: project) }

  context 'editing a MR' do
    before do
      project.team << [user, :master]

      sign_in user

      visit_edit_mr_page
    end

    it 'has class js-quick-submit in form' do
      expect(page).to have_selector('.js-quick-submit')
    end

    it 'warns about version conflict' do
      merge_request.update(title: "New title")

      fill_in 'merge_request_title', with: 'bug 345'
      fill_in 'merge_request_description', with: 'bug description'

      click_button 'Save changes'

      expect(page).to have_content 'Someone edited the merge request the same time you did'
    end

    it 'allows to unselect "Remove source branch"', js: true do
      merge_request.update(merge_params: { 'force_remove_source_branch' => '1' })
      expect(merge_request.merge_params['force_remove_source_branch']).to be_truthy

      visit edit_project_merge_request_path(project, merge_request)
      uncheck 'Remove source branch when merge request is accepted'

      click_button 'Save changes'

      expect(page).to have_unchecked_field 'remove-source-branch-input'
      expect(page).to have_content 'Remove source branch'
    end

    it 'should preserve description textarea height', js: true do
      long_description = %q(
        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Etiam ac ornare ligula, ut tempus arcu. Etiam ultricies accumsan dolor vitae faucibus. Donec at elit lacus. Mauris orci ante, aliquam quis lorem eget, convallis faucibus arcu. Aenean at pulvinar lacus. Ut viverra quam massa, molestie ornare tortor dignissim a. Suspendisse tristique pellentesque tellus, id lacinia metus elementum id. Nam tristique, arcu rhoncus faucibus viverra, lacus ipsum sagittis ligula, vitae convallis odio lacus a nibh. Ut tincidunt est purus, ac vestibulum augue maximus in. Suspendisse vel erat et mi ultricies semper. Pellentesque volutpat pellentesque consequat.

        Cras congue nec ligula tristique viverra. Curabitur fringilla fringilla fringilla. Donec rhoncus dignissim orci ut accumsan. Ut rutrum urna a rhoncus varius. Maecenas blandit, mauris nec accumsan gravida, augue nibh finibus magna, sed maximus turpis libero nec neque. Suspendisse at semper est. Nunc imperdiet dapibus dui, varius sollicitudin erat luctus non. Sed pellentesque ligula eget posuere facilisis. Donec dictum commodo volutpat. Donec egestas dui ac magna sollicitudin bibendum. Vivamus purus neque, ullamcorper ac feugiat et, tempus sit amet metus. Praesent quis viverra neque. Sed bibendum viverra est, eu aliquam mi ornare vitae. Proin et dapibus ipsum. Nunc tortor diam, malesuada nec interdum vel, placerat quis justo. Ut viverra at erat eu laoreet.

        Pellentesque commodo, diam sit amet dignissim condimentum, tortor justo pretium est, non venenatis metus eros ut nunc. Etiam ut neque eget sem dapibus aliquam. Curabitur vel elit lorem. Nulla nec enim elit. Sed ut ex id justo facilisis convallis at ac augue. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Nullam cursus egestas turpis non tristique. Suspendisse in erat sem. Fusce libero elit, fermentum gravida mauris id, auctor iaculis felis. Nullam vulputate tempor laoreet.

        Nam tempor et magna sed convallis. Fusce sit amet sollicitudin risus, a ullamcorper lacus. Morbi gravida quis sem eget porttitor. Donec eu egestas mauris, in elementum tortor. Sed eget ex mi. Mauris iaculis tortor ut est auctor, nec dignissim quam sagittis. Suspendisse vel metus non quam suscipit tincidunt. Cras molestie lacus non justo finibus sodales quis vitae erat. In a porttitor nisi, id sollicitudin urna. Ut at felis tellus. Suspendisse potenti.

        Maecenas leo ligula, varius at neque vitae, ornare maximus justo. Nullam convallis luctus risus et vulputate. Duis suscipit faucibus iaculis. Etiam quis tortor faucibus, tristique tellus sit amet, sodales neque. Nulla dapibus nisi vel aliquet consequat. Etiam faucibus, metus eget condimentum iaculis, enim urna lobortis sem, id efficitur eros sapien nec nisi. Aenean ut finibus ex.
      )

      fill_in 'merge_request_description', with: long_description

      height = get_textarea_height
      find('.js-md-preview-button').click
      find('.js-md-write-button').click
      new_height = get_textarea_height

      expect(height).to eq(new_height)
    end

    def get_textarea_height
      page.evaluate_script('document.getElementById("merge_request_description").offsetHeight')
    end
  end

  context 'saving the MR that needs approvals' do
    before do
      project.team << [user, :master]
      project.update_attributes(approvals_before_merge: 2)

      visit_edit_mr_page
    end

    it 'shows the saved MR' do
      click_button 'Save changes'

      expect(page).to have_link('Close merge request')
    end
  end

  def visit_edit_mr_page
    sign_in(user)

    visit edit_project_merge_request_path(project, merge_request)
  end
end
