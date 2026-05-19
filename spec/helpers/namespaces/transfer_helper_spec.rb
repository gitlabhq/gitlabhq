# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::TransferHelper, feature_category: :groups_and_projects do
  using RSpec::Parameterized::TableSyntax

  include SafeFormatHelper

  let_it_be(:user) { build_stubbed(:user) }

  describe '#show_transfer_banner?' do
    subject { show_transfer_banner?(namespace) }

    context 'when namespace is nil' do
      let_it_be(:namespace) { nil }

      it { is_expected.to be(false) }
    end

    context 'when namespace is not persisted' do
      let_it_be(:namespace) { build_stubbed(:group) }

      it { is_expected.to be(false) }
    end

    context 'when namespace is persisted' do
      # rubocop:disable RSpec/FactoryBot/AvoidCreate -- Need persisted objects
      let_it_be_with_reload(:parent) { create(:group) }
      let_it_be_with_reload(:namespace) { create(:group, parent: parent) }
      # rubocop:enable RSpec/FactoryBot/AvoidCreate

      context 'when namespace transfer is not scheduled or in progress' do
        it { is_expected.to be(false) }
      end

      context 'when namespace transfer is scheduled' do
        before do
          namespace.schedule_transfer!(transition_user: user)
        end

        it { is_expected.to be(true) }

        context 'when namespace transfer is in progress' do
          before do
            namespace.start_transfer!(transition_user: user)
          end

          it { is_expected.to be(true) }
        end
      end
    end
  end

  describe '#transfer_banner_message' do
    let_it_be(:group) { build_stubbed(:group) }
    let_it_be(:project) { build_stubbed(:project) }

    subject { transfer_banner_message(namespace) }

    where(:namespace, :expected_message) do
      # rubocop:disable Layout/LineLength -- TableSyntax
      ref(:group)   | s_('TransferGroup|This group is scheduled for transfer. Users with the Maintainer or Owner role will be notified when the transfer succeeds or fails.')
      ref(:project) | s_('TransferProject|This project is scheduled for transfer. Users with the Maintainer or Owner role will be notified when the transfer succeeds or fails.')
      # rubocop:enable Layout/LineLength
    end

    with_them do
      it { is_expected.to eq(expected_message) }
    end
  end
end
