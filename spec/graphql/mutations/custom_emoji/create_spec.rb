# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::CustomEmoji::Create do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }

  let(:args) { { group_path: group.full_path, name: 'tanuki', url: 'https://about.gitlab.com/images/press/logo/png/gitlab-icon-rgb.png' } }

  before do
    group.add_developer(user)
  end

  describe '#resolve' do
    subject(:resolve) { described_class.new(object: nil, context: { current_user: user }, field: nil).resolve(**args) }

    it 'creates the custom emoji' do
      expect { resolve }.to change(CustomEmoji, :count).by(1)
    end

    it 'sets the creator to be the user who added the emoji' do
      resolve

      expect(CustomEmoji.last.creator).to eq(user)
    end
  end
end
