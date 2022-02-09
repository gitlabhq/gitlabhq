# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Integrations settings form', :js do
  include IntegrationsHelper
  include_context 'project integration activation'

  # Github integration is EE, so let's remove it here.
  integration_names = Integration.available_integration_names - %w[github]
  integrations = integration_names.map do |name|
    Integration.integration_name_to_model(name).new
  end

  # Note: these specs don't validate channel fields
  # which are present on a few integrations
  integrations.each do |integration|
    it "shows on #{integration.title}" do
      visit_project_integration(integration.title)

      aggregate_failures do
        page.within('form.integration-settings-form') do
          expect(page).to have_field('Active', type: 'checkbox', wait: 0),
                          "#{integration.title} active field not present"

          fields = parse_json(fields_for_integration(integration))
          fields.each do |field|
            field_name = field[:name]
            expect(page).to have_field(field[:title], wait: 0),
                            "#{integration.title} field #{field_name} not present"
          end

          events = parse_json(trigger_events_for_integration(integration))
          events.each do |trigger|
            # normalizing the title because capybara location is case sensitive
            title = normalize_title trigger[:title], integration

            expect(page).to have_field(title, type: 'checkbox', wait: 0),
                            "#{integration.title} field #{title} checkbox not present"
          end
        end
      end
    end
  end

  def normalize_title(title, integration)
    return 'Merge request' if integration.is_a?(Integrations::Jira) && title == 'merge_request'

    title.titlecase
  end

  def parse_json(json)
    Gitlab::Json.parse(json, symbolize_names: true)
  end
end
