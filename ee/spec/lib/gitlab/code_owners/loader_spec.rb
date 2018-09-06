# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::CodeOwners::Loader do
  include FakeBlobHelpers
  set(:group) { create(:group) }
  set(:project) { create(:project, namespace: group) }
  subject(:loader) { described_class.new(project, 'with-codeowners', path) }

  let!(:owner_1) { create(:user, username: 'owner-1') }
  let!(:email_owner) { create(:user, username: 'owner-2') }
  let!(:owner_3) { create(:user, username: 'owner-3') }
  let!(:documentation_owner) { create(:user, username: 'documentation-owner') }
  let(:codeowner_content) do
    <<~CODEOWNERS
    docs/* @documentation-owner
    docs/CODEOWNERS @owner-1 owner2@gitlab.org @owner-3 @documentation-owner
    CODEOWNERS
  end
  let(:codeowner_blob) { fake_blob(path: 'CODEOWNERS', data: codeowner_content) }
  let(:path) { 'docs/CODEOWNERS' }

  before do
    create(:email, user: email_owner, email: 'owner2@gitlab.org')
    project.add_developer(owner_1)
    project.add_developer(email_owner)
    project.add_developer(documentation_owner)

    allow(project.repository).to receive(:code_owners_blob).and_return(codeowner_blob)
  end

  describe '#users' do
    context 'with a CODEOWNERS file' do
      context 'for a path with code owners' do
        it 'returns all existing users that are members of the project' do
          expect(loader.users).to contain_exactly(owner_1, email_owner, documentation_owner)
        end

        it 'does not return users that are not members of the project' do
          expect(loader.users).not_to include(owner_3)
        end

        it 'includes group members of the project' do
          group.add_developer(owner_3)

          expect(loader.users).to include(owner_3)
        end
      end

      context 'for another path' do
        let(:path) { 'no-codeowner' }

        it 'returns no users' do
          expect(loader.users).to be_empty
        end
      end
    end

    context 'when there is no codeowners file' do
      let(:codeowner_blob) { nil }

      it 'returns no users without failing' do
        expect(loader.users).to be_empty
      end
    end

    context 'with the request store', :request_store do
      it 'only calls out to the repository once' do
        expect(project.repository).to receive(:code_owners_blob).once

        2.times { loader.users }
      end

      it 'only processes the file once' do
        code_owners_file = loader.__send__(:code_owners_file)

        expect(code_owners_file).to receive(:get_parsed_data).once.and_call_original

        2.times { loader.users }
      end
    end
  end
end
