# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::CustomEmoji::Create do
  include GraphqlHelpers
  let_it_be(:group) { create(:group) }
  let_it_be(:current_user) { create(:user, developer_of: group) }

  let(:args) { { group_path: group.full_path, name: 'tanuki', file: 'https://about.gitlab.com/images/press/logo/png/gitlab-icon-rgb.png' } }

  describe '#resolve' do
    subject(:resolve) { described_class.new(object: nil, context: query_context, field: nil).resolve(**args) }

    it 'creates the custom emoji' do
      expect { resolve }.to change(CustomEmoji, :count).by(1)
    end

    it 'sets the creator to be the user who added the emoji' do
      resolve

      expect(CustomEmoji.last.creator).to eq(current_user)
    end
  end
end
