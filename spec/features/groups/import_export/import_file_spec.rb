# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Import/Export - Group Import', :with_current_organization, :js, feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let_it_be(:import_path) { "#{Dir.tmpdir}/group_import_spec" }

  before_all do
    current_organization.users << user
  end

  before do
    allow_next_instance_of(Gitlab::ImportExport) do |import_export|
      allow(import_export).to receive(:storage_path).and_return(import_path)
    end

    stub_uploads_object_storage(FileUploader)

    gitlab_sign_in(user)
  end

  after do
    FileUtils.rm_rf(import_path, secure: true)
  end

  context 'when the user uploads a valid export file' do
    let(:file) { File.join(Rails.root, 'spec', %w[fixtures group_export.tar.gz]) }

    context 'when using the pre-filled path', :sidekiq_inline do
      it 'successfully imports the group' do
        group_name = 'Test Group Import'

        visit new_group_path
        click_link 'Import group'

        fill_in s_('Groups|Group name'), with: group_name

        expect(page).to have_content 'Import group from file'
        attach_file(file) do
          find('.js-filepicker-button').click
        end

        expect { click_on 'Import' }.to change { Group.count }.by 1

        group = Group.find_by(name: group_name)

        aggregate_failures do
          expect(group).not_to be_nil
          expect(group.description).to eq 'A voluptate non sequi temporibus quam at.'
          expect(group.path).to eq 'test-group-import'
          expect(group.import_state.status).to eq GroupImportState.state_machine.states[:finished].value
        end
      end
    end

    context 'when modifying the pre-filled path' do
      it 'successfully imports the group' do
        visit new_group_path
        click_link 'Import group'

        fill_in s_('Groups|Group name'), with: 'Test Group Import'

        fill_in s_('Groups|Group URL'), with: 'custom-path'
        attach_file(file) do
          find('.js-filepicker-button').click
        end

        expect { click_on 'Import' }.to change { Group.count }.by 1

        group = Group.find_by(name: 'Test Group Import')
        expect(group.path).to eq 'custom-path'
      end
    end

    context 'when the path is already taken' do
      before do
        create(:group, path: 'test-group-import')
      end

      it 'suggests a unique path' do
        visit new_group_path
        click_link 'Import group'

        fill_in s_('Groups|Group URL'), with: 'test-group-import'
        expect(page).to have_content s_(
          'Groups|Group path is unavailable. Path has been replaced with a suggested available path.'
        )
      end
    end
  end

  context 'when the user uploads an invalid export file' do
    let(:file) { File.join(Rails.root, 'spec', %w[fixtures big-image.png]) }

    it 'displays an error', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/343995' do
      visit new_group_path
      click_link 'Import group'

      fill_in s_('Groups|Group name'), with: 'Test Group Import'
      attach_file(file) do
        find('.js-filepicker-button').click
      end

      expect { click_on 'Import' }.not_to change { Group.count }

      page.within('.flash-container') do
        expect(page).to have_content('Unable to process group import file')
      end
    end
  end
end
