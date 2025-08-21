# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::ArchiveHelper, feature_category: :groups_and_projects do
  using RSpec::Parameterized::TableSyntax

  include SafeFormatHelper

  describe '#show_archived_banner?' do
    subject { show_archived_banner?(namespace) }

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

      context 'when namespace is not archived' do
        it { is_expected.to be(false) }
      end

      context 'when namespace is archived' do
        before do
          namespace.archive
        end

        it { is_expected.to be(true) }
      end

      context 'when has archived ancestor' do
        before do
          parent.archive
        end

        it { is_expected.to be(true) }
      end
    end
  end

  describe '#archived_banner_message' do
    let_it_be_with_reload(:parent) { create(:group) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- Needs persisted object

    let_it_be(:group) { build_stubbed(:group, :archived, parent: parent) }
    let_it_be(:project) { build_stubbed(:project, :archived, group: parent) }
    let_it_be(:project_presenter) { ProjectPresenter.new(project) }

    subject { archived_banner_message(namespace) }

    where(:namespace_type, :has_archived_ancestor, :expected_message) do
      # rubocop:disable Layout/LineLength -- TableSyntax
      :group             | false | 'This group is archived. Its subgroups, projects, and data are %{strong_open}read-only%{strong_close}.'
      :group             | true  | 'The parent group is archived. This group and its data are %{strong_open}read-only%{strong_close}.'
      :project           | false | 'This project is archived. Its data is %{strong_open}read-only%{strong_close}.'
      :project           | true  | 'The parent group is archived. This project and its data are %{strong_open}read-only%{strong_close}.'
      :project_presenter | false | 'This project is archived. Its data is %{strong_open}read-only%{strong_close}.'
      :project_presenter | true  | 'The parent group is archived. This project and its data are %{strong_open}read-only%{strong_close}.'
      # rubocop:enable Layout/LineLength
    end

    with_them do
      let(:namespace) { namespace_type == :group ? group : project }

      before do
        parent.archive if has_archived_ancestor
      end

      it 'returns expected message' do
        is_expected.to eq(safe_format(
          _(expected_message),
          tag_pair(tag.strong, :strong_open, :strong_close)
        ))
      end
    end

    context 'when namespace type is not supported' do
      let_it_be(:user_namespace) { build_stubbed(:namespace, type: 'User') }

      it 'raises an error' do
        expect { archived_banner_message(user_namespace) }
          .to raise_error(RuntimeError, "Unsupported namespace type: #{user_namespace.class.name}")
      end
    end
  end
end
