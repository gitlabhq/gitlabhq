# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::GroupDismissibleAlertComponent, feature_category: :shared do
  context 'with group dismissible alert behavior' do
    let(:group) { build_stubbed(:group) }
    let(:callout_model) { Users::GroupCallout }
    let(:dismissal_method) { :dismissed_callout_for_group? }
    let(:dismiss_options) { { user: user, feature_id: feature_id, group: group } }
    let(:dismiss_endpoint) { group_callouts_path }
    let(:resource_data_attribute) { { key: :group, name: 'group-id' } }

    it_behaves_like 'dismissible alert component' do
      context 'when group is missing' do
        let(:dismiss_options) { super().merge(group: nil) }

        it 'raises ArgumentError for missing group' do
          expect do
            rendered_component
          end.to raise_error(ArgumentError, 'dismiss_options[:group] is required')
        end
      end
    end
  end
end
