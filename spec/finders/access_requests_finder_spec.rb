# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AccessRequestsFinder do
  let(:user) { create(:user) }
  let(:access_requester) { create(:user) }

  let(:project) do
    create(:project, :public) do |project|
      project.request_access(access_requester)
    end
  end

  let(:group) do
    create(:group, :public) do |group|
      group.request_access(access_requester)
    end
  end

  shared_examples 'a finder returning access requesters' do |method_name|
    it 'returns access requesters' do
      access_requesters = described_class.new(source).public_send(method_name, user)

      expect(access_requesters.size).to eq(1)
      expect(access_requesters.first).to be_a "#{source.class}Member".constantize
      expect(access_requesters.first.user).to eq(access_requester)
    end
  end

  shared_examples 'a finder returning no results' do |method_name|
    it 'raises Gitlab::Access::AccessDeniedError' do
      expect(described_class.new(source).public_send(method_name, user)).to be_empty
    end
  end

  shared_examples 'a finder raising Gitlab::Access::AccessDeniedError' do |method_name|
    it 'raises Gitlab::Access::AccessDeniedError' do
      expect { described_class.new(source).public_send(method_name, user) }.to raise_error(Gitlab::Access::AccessDeniedError)
    end
  end

  shared_examples '#execute' do
    context 'when current user cannot see project access requests' do
      it_behaves_like 'a finder returning no results', :execute do
        let(:source) { project }
      end

      it_behaves_like 'a finder returning no results', :execute do
        let(:source) { group }
      end
    end

    context 'when current user can see access requests' do
      before do
        project.add_maintainer(user)
        group.add_owner(user)
      end

      it_behaves_like 'a finder returning access requesters', :execute do
        let(:source) { project }
      end

      it_behaves_like 'a finder returning access requesters', :execute do
        let(:source) { group }
      end
    end
  end

  shared_examples '#execute!' do
    context 'when current user cannot see access requests' do
      it_behaves_like 'a finder raising Gitlab::Access::AccessDeniedError', :execute! do
        let(:source) { project }
      end

      it_behaves_like 'a finder raising Gitlab::Access::AccessDeniedError', :execute! do
        let(:source) { group }
      end
    end

    context 'when current user can see access requests' do
      before do
        project.add_maintainer(user)
        group.add_owner(user)
      end

      it_behaves_like 'a finder returning access requesters', :execute! do
        let(:source) { project }
      end

      it_behaves_like 'a finder returning access requesters', :execute! do
        let(:source) { group }
      end
    end
  end

  it_behaves_like '#execute'
  it_behaves_like '#execute!'
end
