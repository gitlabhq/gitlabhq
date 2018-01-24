require 'spec_helper'

describe 'admin/groups/_form' do
  set(:admin) { create(:admin) }

  before do
    assign(:group, group)
    allow(view).to receive(:can?) { true }
    allow(view).to receive(:current_user) { admin }
    allow(view).to receive(:visibility_level) { group.visibility_level }
  end

  describe 'when :shared_runner_minutes_on_root_namespace is disabled' do
    before do
      stub_feature_flags(shared_runner_minutes_on_root_namespace: false)
    end

    context 'when sub group is used' do
      let(:root_ancestor) { create(:group) }
      let(:group) { build(:group, parent: root_ancestor) }

      it 'renders shared_runners_minutes_setting' do
        render

        expect(rendered).to render_template('namespaces/_shared_runners_minutes_setting')
      end
    end
  end

  describe 'when :shared_runner_minutes_on_root_namespace is enabled', :nested_groups do
    before do
      stub_feature_flags(shared_runner_minutes_on_root_namespace: true)
    end

    context 'when sub group is used' do
      let(:root_ancestor) { create(:group) }
      let(:group) { build(:group, parent: root_ancestor) }

      it 'does not render shared_runners_minutes_setting' do
        render

        expect(rendered).not_to render_template('namespaces/_shared_runners_minutes_setting')
      end
    end

    context 'when root group is used' do
      let(:group) { build(:group) }

      it 'does not render shared_runners_minutes_setting' do
        render

        expect(rendered).to render_template('namespaces/_shared_runners_minutes_setting')
      end
    end
  end
end
