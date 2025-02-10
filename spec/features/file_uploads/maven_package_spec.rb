# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Upload a maven package', :api, :js, feature_category: :package_registry do
  include_context 'file upload requests helpers'

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { project.first_owner }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }

  let(:project_id) { project.id }
  let(:api_path) { "/projects/#{project_id}/packages/maven/com/example/my-app/1.0/my-app-1.0-20180724.124855-1.jar" }
  let(:url) { capybara_url(api(api_path, personal_access_token: personal_access_token)) }
  let(:file) { fixture_file_upload('spec/fixtures/dk.png') }

  subject { HTTParty.put(url, body: file.read) }

  shared_examples 'for a maven package' do
    it 'creates package files' do
      expect { subject }
        .to change { ::Packages::Maven::Package.count }.by(1)
        .and change { Packages::PackageFile.count }.by(1)
    end

    it { expect(subject.code).to eq(200) }
  end

  shared_examples 'for a maven sha1' do
    let(:dummy_package) { double(Packages::Package) }
    let(:api_path) { "/projects/#{project_id}/packages/maven/com/example/my-app/1.0/my-app-1.0-20180724.124855-1.jar.sha1" }

    before do
      # The sha verification done by the maven api is between:
      # - the sha256 set by workhorse
      # - the sha256 of the sha1 of the uploaded package file
      # We're going to send `file` for the sha1 and stub the sha1 of the package file so that
      # both sha256 being the same
      expect(::Packages::PackageFileFinder).to receive(:new).and_return(double(execute!: dummy_package))
      expect(dummy_package).to receive(:file_sha1).and_return(File.read(file.path))
    end

    it { expect(subject.code).to eq(204) }
  end

  shared_examples 'for a maven md5' do
    let(:api_path) { "/projects/#{project_id}/packages/maven/com/example/my-app/1.0/my-app-1.0-20180724.124855-1.jar.md5" }
    let(:file) { StringIO.new('dummy_package') }

    it { expect(subject.code).to eq(200) }
  end

  it_behaves_like 'handling file uploads', 'for a maven package'
  it_behaves_like 'handling file uploads', 'for a maven sha1'
  it_behaves_like 'handling file uploads', 'for a maven md5'

  context 'with an encoded project ID' do
    let(:project_id) { "#{project.namespace.path}%2F#{project.path}" }

    it_behaves_like 'handling file uploads', 'for a maven package'
  end
end
