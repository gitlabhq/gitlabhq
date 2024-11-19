# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UploaderFinder, feature_category: :shared do
  describe '#execute' do
    let(:upload) { create(:upload, :issuable_upload, :with_file) }
    let(:secret) { upload.secret }
    let(:file_name) { upload.path }

    subject { described_class.new(container, secret, file_name).execute }

    before do
      upload.save!
    end

    RSpec.shared_examples 'find upload' do
      context 'when successful' do
        before do
          allow_next_instance_of(uploader_class) do |uploader|
            allow(uploader).to receive(:retrieve_from_store!).with(upload.path).and_return(uploader)
          end
        end

        it 'gets the file-like uploader' do
          uploader_model = container.is_a?(Namespaces::ProjectNamespace) ? container.project : container

          expect(subject).to be_an_instance_of(uploader_class)
          expect(subject.model).to eq(uploader_model)
          expect(subject.secret).to eq(secret)
        end
      end

      context 'when path traversal in file name' do
        before do
          upload.path = '/uploads/111111111111111111111111111111/../../../../../../../../../../../../../../etc/passwd)'
          upload.save!
        end

        it 'returns nil' do
          expect(subject).to be(nil)
        end
      end

      context 'when unexpected failure' do
        before do
          allow_next_instance_of(uploader_class) do |uploader|
            allow(uploader).to receive(:retrieve_from_store!).and_raise(StandardError)
          end
        end

        it 'returns nil when unexpected error is raised' do
          expect { subject }.to raise_error(StandardError)
        end
      end
    end

    context 'when container is a project' do
      let(:project) { build(:project) }
      let(:container) { project }
      let(:uploader_class) { FileUploader }

      it_behaves_like 'find upload'
    end

    context 'when container is a project namespace' do
      let(:project) { build(:project) }
      let(:project_namespace) { build(:project_namespace, project: project) }
      let(:container) { project.project_namespace }
      let(:uploader_class) { FileUploader }

      it_behaves_like 'find upload'
    end

    context 'when container is a group' do
      let(:group) { build(:group) }
      let(:container) { group }
      let(:uploader_class) { NamespaceFileUploader }

      it_behaves_like 'find upload'
    end
  end
end
