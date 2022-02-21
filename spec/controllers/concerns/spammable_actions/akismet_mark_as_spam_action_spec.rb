# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SpammableActions::AkismetMarkAsSpamAction do
  include AfterNextHelpers

  controller(ActionController::Base) do
    include SpammableActions::AkismetMarkAsSpamAction
  end

  let(:spammable_type) { 'SpammableType' }
  let(:spammable) { double(:spammable, spammable_entity_type: double(:spammable_entity_type, titlecase: spammable_type)) }
  let(:current_user) { create(:admin) }

  before do
    allow(Gitlab::Recaptcha).to receive(:load_configurations!) { true }
    routes.draw { get 'mark_as_spam' => 'anonymous#mark_as_spam' }
    allow(controller).to receive(:current_user) { double(:current_user, admin?: admin) }
    allow(controller).to receive(:current_user).and_return(current_user)
  end

  describe '#mark_as_spam' do
    subject { post :mark_as_spam }

    before do
      allow(controller).to receive(:spammable) { spammable }
      allow(controller).to receive(:spammable_path) { '/fake_spammable_path' }

      expect_next(Spam::AkismetMarkAsSpamService, target: spammable)
        .to receive(:execute).and_return(execute_result)
    end

    context 'when user is admin', :enable_admin_mode do
      let(:admin) { true }

      context 'when service returns truthy' do
        let(:execute_result) { true }

        it 'redirects with notice' do
          expect(subject).to redirect_to('/fake_spammable_path')
          expect(subject.request.flash[:notice]).to match(/#{spammable_type}.*submitted.*successfully/)
        end
      end

      context 'when service returns falsey' do
        let(:execute_result) { false }

        it 'redirects with notice' do
          expect(subject).to redirect_to('/fake_spammable_path')
          expect(subject.request.flash[:alert]).to match(/Error/)
        end
      end
    end

    context 'when user is not admin' do
      let(:admin) { false }
      let(:execute_result) { true }

      it 'calls #access_denied!' do
        expect(controller).to receive(:access_denied!) { false }

        subject
      end
    end
  end

  describe '#spammable' do
    it 'raises when unimplemented' do
      expect { controller.send(:spammable) }.to raise_error(NotImplementedError)
    end
  end

  describe '#spammable_path' do
    it 'raises when unimplemented' do
      expect { controller.send(:spammable_path) }.to raise_error(NotImplementedError)
    end
  end
end
