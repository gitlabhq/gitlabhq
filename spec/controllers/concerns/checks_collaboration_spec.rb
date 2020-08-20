# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ChecksCollaboration do
  include ProjectForksHelper

  let(:helper) do
    fake_class = Class.new(ApplicationController) do
      include ChecksCollaboration
    end

    fake_class.new
  end

  describe '#can_collaborate_with_project?' do
    let(:user) { create(:user) }
    let(:project) { create(:project, :public) }

    before do
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:can?) do |user, ability, subject|
        Ability.allowed?(user, ability, subject)
      end
    end

    it 'is true if the user can push to the project' do
      project.add_developer(user)

      expect(helper.can_collaborate_with_project?(project)).to be_truthy
    end

    it 'is true when the user can push to a branch of the project' do
      fake_access = double('Gitlab::UserAccess')
      expect(fake_access).to receive(:can_push_to_branch?).with('a-branch').and_return(true)
      expect(Gitlab::UserAccess).to receive(:new).with(user, container: project).and_return(fake_access)

      expect(helper.can_collaborate_with_project?(project, ref: 'a-branch')).to be_truthy
    end

    context 'when the user has forked the project' do
      before do
        fork_project(project, user, namespace: user.namespace)
      end

      it 'is true' do
        expect(helper.can_collaborate_with_project?(project)).to be_truthy
      end

      it 'is false when the project is archived' do
        project.archived = true

        expect(helper.can_collaborate_with_project?(project)).to be_falsy
      end
    end
  end
end
