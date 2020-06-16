# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ForkTargetsFinder do
  subject(:finder) { described_class.new(project, user) }

  let(:project) { create(:project, namespace: create(:group)) }
  let(:user) { create(:user) }
  let!(:maintained_group) do
    create(:group).tap { |g| g.add_maintainer(user) }
  end
  let!(:owned_group) do
    create(:group).tap { |g| g.add_owner(user) }
  end
  let!(:developer_group) do
    create(:group).tap { |g| g.add_developer(user) }
  end
  let!(:reporter_group) do
    create(:group).tap { |g| g.add_reporter(user) }
  end
  let!(:guest_group) do
    create(:group).tap { |g| g.add_guest(user) }
  end

  before do
    project.namespace.add_owner(user)
  end

  describe '#execute' do
    it 'returns all user manageable namespaces' do
      expect(finder.execute).to match_array([user.namespace, maintained_group, owned_group, project.namespace])
    end
  end
end
