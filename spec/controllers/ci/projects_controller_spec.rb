require 'spec_helper'

describe Ci::ProjectsController do
  let(:visibility) { :public }
  let!(:project) { create(:project, visibility, ci_id: 1) }
  let(:ci_id) { project.ci_id }

  ##
  # Specs for *deprecated* CI badge
  #
  describe '#badge' do
    shared_examples 'badge provider' do
      it 'shows badge' do
        expect(response.status).to eq 200
        expect(response.headers)
          .to include('Content-Type' => 'image/svg+xml')
      end
    end

    context 'user not signed in' do
      before { get(:badge, id: ci_id) }

      context 'project has no ci_id reference' do
        let(:ci_id) { 123 }

        it 'returns 404' do
          expect(response.status).to eq 404
        end
      end

      context 'project is public' do
        let(:visibility) { :public }
        it_behaves_like 'badge provider'
      end

      context 'project is private' do
        let(:visibility) { :private }
        it_behaves_like 'badge provider'
      end
    end

    context 'user signed in' do
      let(:user) { create(:user) }
      before { sign_in(user) }
      before { get(:badge, id: ci_id) }

      context 'private is internal' do
        let(:visibility) { :internal }
        it_behaves_like 'badge provider'
      end
    end
  end
end
