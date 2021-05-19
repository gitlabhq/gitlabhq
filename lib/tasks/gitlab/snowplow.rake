# frozen_string_literal: true

namespace :gitlab do
  namespace :snowplow do
    desc 'GitLab | Snowplow | Generate event dictionary'
    task generate_event_dictionary: :environment do
      items = Gitlab::Tracking::EventDefinition.definitions
      Gitlab::Tracking::Docs::Renderer.new(items).write
    end
  end
end
