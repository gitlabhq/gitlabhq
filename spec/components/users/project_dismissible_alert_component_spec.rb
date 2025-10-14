# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::ProjectDismissibleAlertComponent, feature_category: :shared do
  let(:project) { build_stubbed(:project) }
  let(:callout_model) { Users::ProjectCallout }
  let(:dismissal_method) { :dismissed_callout_for_project? }
  let(:dismiss_options) { { user: user, feature_id: feature_id, project: project } }
  let(:dismiss_endpoint) { project_callouts_path }
  let(:resource_data_attribute) { { key: :project, name: 'project-id' } }

  it_behaves_like 'dismissible alert component' do
    context 'when project is missing' do
      let(:dismiss_options) { super().merge(project: nil) }

      it 'raises ArgumentError for missing project' do
        expect do
          rendered_component
        end.to raise_error(ArgumentError, 'dismiss_options[:project] is required')
      end
    end
  end
end
