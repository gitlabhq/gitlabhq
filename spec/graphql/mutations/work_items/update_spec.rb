# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::WorkItems::Update, feature_category: :portfolio_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:current_work_item) { create(:work_item, :task, project: project) }
  let_it_be(:parent_work_item) { create(:work_item, project: project) }

  subject(:mutation) { described_class.new(object: nil, context: query_context, field: nil) }

  describe '#ready?' do
    let(:current_user) { developer }
    let(:current_gid) { current_work_item.to_gid.to_s }
    let(:parent_gid) { parent_work_item.to_gid.to_s }
    let(:valid_arguments) { { id: current_gid, parent_id: parent_gid } }

    it { is_expected.to be_ready(**valid_arguments) }
  end
end
