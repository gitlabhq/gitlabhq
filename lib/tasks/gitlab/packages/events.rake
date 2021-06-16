# frozen_string_literal: true

require 'logger'

desc "GitLab | Packages | Events | Generate hll counter events file for packages"
namespace :gitlab do
  namespace :packages do
    namespace :events do
      task generate: :environment do
        Rake::Task["gitlab:packages:events:generate_counts"].invoke
        Rake::Task["gitlab:packages:events:generate_unique"].invoke
      rescue StandardError => e
        logger.error("Error building events list: #{e}")
      end

      task generate_counts: :environment do
        logger = Logger.new($stdout)
        logger.info('Building list of package events...')

        path = Gitlab::UsageDataCounters::PackageEventCounter::KNOWN_EVENTS_PATH
        File.open(path, "w") { |file| file << counter_events_list.to_yaml }

        logger.info("Events file `#{path}` generated successfully")
      rescue StandardError => e
        logger.error("Error building events list: #{e}")
      end

      task generate_unique: :environment do
        logger = Logger.new($stdout)
        logger.info('Building list of package events...')

        path = File.join(File.dirname(Gitlab::UsageDataCounters::HLLRedisCounter::KNOWN_EVENTS_PATH), 'package_events.yml')
        File.open(path, "w") { |file| file << generate_unique_events_list.to_yaml }

        logger.info("Events file `#{path}` generated successfully")
      rescue StandardError => e
        logger.error("Error building events list: #{e}")
      end

      private

      def event_pairs
        Packages::Event.event_types.keys.product(Packages::Event::EVENT_SCOPES.keys)
      end

      def generate_unique_events_list
        events = event_pairs.each_with_object([]) do |(event_type, event_scope), events|
          Packages::Event.originator_types.keys.excluding('guest').each do |originator_type|
            events_definition = Packages::Event.unique_counters_for(event_scope, event_type, originator_type).map do |event_name|
              {
                "name" => event_name,
                "category" => "#{originator_type}_packages",
                "aggregation" => "weekly",
                "redis_slot" => "package"
              }
            end

            events.concat(events_definition)
          end
        end

        events.sort_by { |event| event["name"] }.uniq
      end

      def counter_events_list
        counters = event_pairs.flat_map do |event_type, event_scope|
          Packages::Event.originator_types.keys.flat_map do |originator_type|
            Packages::Event.counters_for(event_scope, event_type, originator_type)
          end
        end

        counters.compact.sort.uniq
      end
    end
  end
end
