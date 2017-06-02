module SystemCheck
  module App
    class ElasticsearchCheck < SystemCheck::BaseCheck
      set_name 'Elasticsearch version 5.1 - 5.3?'
      set_skip_reason 'skipped (elasticsearch is disabled)'
      set_check_pass -> { "yes (#{self.current_version})" }
      set_check_fail -> { "no (#{self.current_version})" }

      def self.current_version
        @current_version ||= begin
          client = Gitlab::Elastic::Client.build(current_application_settings.elasticsearch_config)
          Gitlab::VersionInfo.parse(client.info['version']['number'])
        end
      end

      def skip?
        !current_application_settings.elasticsearch_indexing?
      end

      def check?
        current_version.major == 5 && (1..3).cover?(version.minor)
      end
    end
  end
end
