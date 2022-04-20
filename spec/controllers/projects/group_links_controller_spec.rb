# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::GroupLinksController do
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:group2) { create(:group, :private) }
  let_it_be(:project) { create(:project, :private, group: group2) }
  let_it_be(:user) { create(:user) }

  before do
    travel_to DateTime.new(2019, 4, 1)
    project.add_maintainer(user)
    sign_in(user)
  end

  after do
    travel_back
  end

  describe '#update' do
    let_it_be(:link) do
      create(
        :project_group_link,
        {
          project: project,
          group: group
        }
      )
    end

    let(:expiry_date) { 1.month.from_now.to_date }

    before do
      travel_to Time.now.utc.beginning_of_day

      put(
        :update,
        params: {
          namespace_id: project.namespace.to_param,
          project_id: project.to_param,
          id: link.id,
          group_link: { group_access: Gitlab::Access::GUEST, expires_at: expiry_date }
        },
        format: :json
      )
    end

    context 'when `expires_at` is set' do
      it 'returns correct json response' do
        expect(json_response).to eq({ "expires_in" => controller.helpers.time_ago_with_tooltip(expiry_date), "expires_soon" => false })
      end
    end

    context 'when `expires_at` is not set' do
      let(:expiry_date) { nil }

      it 'returns empty json response' do
        expect(json_response).to be_empty
      end
    end
  end
end
