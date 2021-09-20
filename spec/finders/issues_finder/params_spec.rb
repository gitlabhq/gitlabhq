# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssuesFinder::Params do
  describe '#include_hidden' do
    subject { described_class.new(params, user, IssuesFinder) }

    context 'when param is not set' do
      let(:params) { {} }

      context 'with an admin', :enable_admin_mode do
        let(:user) { create(:user, :admin) }

        it 'returns true' do
          expect(subject.include_hidden?).to be_truthy
        end
      end

      context 'with a regular user' do
        let(:user) { create(:user) }

        it 'returns false' do
          expect(subject.include_hidden?).to be_falsey
        end
      end
    end

    context 'when param is set' do
      let(:params) { { include_hidden: true } }

      context 'with an admin', :enable_admin_mode do
        let(:user) { create(:user, :admin) }

        it 'returns true' do
          expect(subject.include_hidden?).to be_truthy
        end
      end

      context 'with a regular user' do
        let(:user) { create(:user) }

        it 'returns false' do
          expect(subject.include_hidden?).to be_falsey
        end
      end
    end
  end
end
