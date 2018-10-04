require 'spec_helper'

describe 'Referencing Epics', :js do
  let(:user) { create(:user) }
  let(:group) { create(:group, :public) }
  let(:epic) { create(:epic, group: group) }
  let(:project) { create(:project, :public) }

  let(:full_reference) { epic.to_reference(full: true) }

  context 'reference on an issue' do
    before do
      stub_licensed_features(epics: true)

      sign_in(user)
    end

    context 'when referencing epics from the direct parent' do
      let(:epic2) { create(:epic, group: group) }
      let(:short_reference) { epic2.to_reference }
      let(:text) { "Check #{full_reference} #{short_reference}" }
      let(:child_project) { create(:project, :public, group: group) }
      let(:issue) { create(:issue, project: child_project, description: text) }

      it 'displays link to the reference' do
        visit project_issue_path(child_project, issue)

        page.within('.issuable-details .description') do
          expect(page).to have_link(epic.to_reference, href: group_epic_path(group, epic))
          expect(page).to have_link(short_reference, href: group_epic_path(group, epic2))
        end
      end
    end

    context 'when referencing an epic from another group' do
      let(:text) { "Check #{full_reference}" }
      let(:issue) { create(:issue, project: project, description: text) }

      context 'when non group member displays the issue' do
        context 'when referenced epic is in a public group' do
          it 'displays link to the reference' do
            visit project_issue_path(project, issue)

            page.within('.issuable-details .description') do
              expect(page).to have_link(full_reference, href: group_epic_path(group, epic))
            end
          end
        end

        context 'when referenced epic is in a private group' do
          before do
            group.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
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
            group.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
          end

          it 'displays link to the reference' do
            visit project_issue_path(project, issue)

            page.within('.issuable-details .description') do
              expect(page).to have_link(full_reference, href: group_epic_path(group, epic))
            end
          end
        end
      end
    end
  end

  context 'note cross-referencing' do
    let(:issue) { create(:issue, project: project) }

    before do
      stub_licensed_features(epics: true)
      group.add_developer(user)

      sign_in(user)
    end

    context 'when referencing an epic from an issue note' do
      let(:note_text) { "Check #{epic.to_reference(full: true)}" }

      before do
        visit project_issue_path(project, issue)

        fill_in 'note[note]', with: note_text
        click_button 'Comment'

        wait_for_requests
      end

      it 'creates a note with reference and cross references the epic' do
        page.within('div#notes li.note div.note-text') do
          expect(page).to have_content(note_text)
          expect(page.find('a')).to have_content(epic.to_reference(full: true))
        end

        find('div#notes li.note div.note-text a').click

        page.within('div#notes li.note .system-note-message') do
          expect(page).to have_content('mentioned in issue')
          expect(page.find('a')).to have_content(issue.to_reference(full: true))
        end
      end

      context 'when referencing an issue from an epic' do
        let(:note_text) { "Check #{issue.to_reference(full: true)}" }

        before do
          visit group_epic_path(group, epic)

          fill_in 'note[note]', with: note_text
          click_button 'Comment'

          wait_for_requests
        end

        it 'creates a note with reference and cross references the issue' do
          page.within('div#notes li.note div.note-text') do
            expect(page).to have_content(note_text)
            expect(page.find('a')).to have_content(issue.to_reference(full: true))
          end

          find('div#notes li.note div.note-text a').click

          page.within('div#notes li.note .system-note-message') do
            expect(page).to have_content('mentioned in epic')
            expect(page.find('a')).to have_content(epic.to_reference(full: true))
          end
        end
      end
    end
  end
end
