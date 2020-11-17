require 'logger'

desc "GitLab | Packages | Events | Generate hll counter events file for packages"
namespace :gitlab do
  namespace :packages do
    namespace :events do
      task generate: :environment do
        logger = Logger.new(STDOUT)
        logger.info('Building list of package events...')

        path = File.join(File.dirname(::Gitlab::UsageDataCounters::HLLRedisCounter::KNOWN_EVENTS_PATH), 'package_events.yml')

        File.open(path, "w") { |file| file << generate_unique_events_list.to_yaml }

        logger.info("Events file `#{path}` generated successfully")
      rescue => e
        logger.error("Error building events list: #{e}")
      end

      def event_pairs
        ::Packages::Event.event_types.keys.product(::Packages::Event.originator_types.keys)
      end

      def generate_unique_events_list
        ::Packages::Event::EVENT_SCOPES.keys.each_with_object([]) do |event_scope, events|
          event_pairs.each do |event_type, originator|
            if name = ::Packages::Event.allowed_event_name(event_scope, event_type, originator)
              events << {
                "name" => name,
                "category" => "#{event_scope}_packages",
                "aggregation" => "weekly",
                "redis_slot" => "package"
              }
            end
          end
        end
      end
    end
  end
end
