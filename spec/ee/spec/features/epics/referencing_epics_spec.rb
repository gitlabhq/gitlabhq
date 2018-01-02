require 'spec_helper'

describe 'Referencing Epics', :js do
  let(:user) { create(:user) }
  let(:group) { create(:group, :public) }
  let(:epic) { create(:epic, group: group) }
  let(:project) { create(:project, :public) }

  let(:reference) { epic.to_reference(full: true) }

  context 'reference on an issue' do
    let(:issue) { create(:issue, project: project, description: "Check #{reference}") }

    before do
      stub_licensed_features(epics: true)

      sign_in(user)
    end

    context 'when non group member displays the issue' do
      context 'when referenced epic is in a public group' do
        it 'displays link to the reference' do
          visit project_issue_path(project, issue)

          page.within('.issuable-details .description') do
            expect(page).to have_link(reference, href: group_epic_path(group, epic))
          end
        end
      end

      context 'when referenced epic is in a private group' do
        before do
          group.update_attribute(:visibility_level, Gitlab::VisibilityLevel::PRIVATE)
        end

        it 'does not display link to the reference' do
          visit project_issue_path(project, issue)

          page.within('.issuable-details .description') do
            expect(page).not_to have_link
          end
        end
      end
    end

    context 'when a group member displays the issue' do
      context 'when referenced epic is in a private group' do
        before do
          group.add_developer(user)
          group.update_attribute(:visibility_level, Gitlab::VisibilityLevel::PRIVATE)
        end

        it 'displays link to the reference' do
          visit project_issue_path(project, issue)

          page.within('.issuable-details .description') do
            expect(page).to have_link(reference, href: group_epic_path(group, epic))
          end
        end
      end
    end
  end
end
