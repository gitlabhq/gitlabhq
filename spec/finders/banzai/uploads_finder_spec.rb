# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::UploadsFinder, feature_category: :markdown do
  let_it_be(:project) { create(:project) }
  let_it_be(:project_upload_1) { create(:upload, :issuable_upload, model: project, filename: 'file1.jpg') }
  let_it_be(:project_upload_2) { create(:upload, :issuable_upload, model: project, filename: 'file2.jpg') }
  let_it_be(:project_upload_3) { create(:upload, :issuable_upload, model: project, filename: 'file3.jpg') }
  let_it_be(:project_avatar) { create(:upload, model: project) }
  let_it_be(:other_project_upload) { create(:upload, :issuable_upload, model: create(:project)) }

  let_it_be(:group) { create(:group) }
  let_it_be(:group_upload_1) { create(:upload, :namespace_upload, model: group, filename: 'file4.jpg') }
  let_it_be(:group_upload_2) { create(:upload, :namespace_upload, model: group, filename: 'file5.jpg') }
  let_it_be(:group_upload_3) { create(:upload, :namespace_upload, model: group, filename: 'file6.jpg') }
  let_it_be(:group_avatar) { create(:upload, model: group) }
  let_it_be(:other_group_upload) { create(:upload, :namespace_upload, model: create(:group)) }

  let(:finder) { described_class.new(parent: parent) }

  describe '#execute' do
    context 'for project uploads' do
      let(:parent) { project }

      it 'returns Markdown uploads ordered by created_at DESC' do
        expect(finder.execute).to eq([project_upload_3, project_upload_2, project_upload_1])
      end
    end

    context 'for group uploads' do
      let(:parent) { group }

      it 'returns Markdown uploads ordered by created_at DESC' do
        expect(finder.execute).to eq([group_upload_3, group_upload_2, group_upload_1])
      end
    end

    context 'when invalid parent is given' do
      let(:parent) { project.owner }

      it 'raises an ArgumentError' do
        expect { finder.execute }.to raise_error(ArgumentError, 'unknown uploader for User')
      end
    end
  end

  describe '#find_by_secret_and_filename' do
    let(:parent) { project }

    it 'returns upload by secret and filename' do
      upload = finder.find_by_secret_and_filename(project_upload_1.secret, 'file1.jpg')

      expect(upload).to eq(project_upload_1)
    end

    context 'when filename does not match' do
      it 'returns nil' do
        upload = finder.find_by_secret_and_filename(project_upload_1.secret, 'wrongfile1.jpg')

        expect(upload).to be_nil
      end
    end

    context 'when secret does not match' do
      it 'returns nil' do
        upload = finder.find_by_secret_and_filename(project_upload_2.secret, 'file1.jpg')

        expect(upload).to be_nil
      end
    end

    context 'when secret is invalid' do
      it 'returns nil' do
        upload = finder.find_by_secret_and_filename('wrongsecret', 'file1.jpg')

        expect(upload).to be_nil
      end
    end

    context 'when parent is invalid' do
      let(:parent) { group }

      it 'returns nil' do
        upload = finder.find_by_secret_and_filename(project_upload_1.secret, 'file1.jpg')

        expect(upload).to be_nil
      end
    end
  end
end
