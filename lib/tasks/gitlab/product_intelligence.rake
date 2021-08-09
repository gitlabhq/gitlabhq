# frozen_string_literal: true

namespace :gitlab do
  namespace :product_intelligence do
    # @example
    #   bundle exec rake gitlab:product_intelligence:activate_metrics MILESTONE=14.0

    desc 'GitLab | Product Intelligence | Update milestone metrics status to data_available'
    task activate_metrics: :environment do
      milestone = ENV['MILESTONE']
      raise "Please supply the MILESTONE env var".color(:red) unless milestone.present?

      Gitlab::Usage::MetricDefinition.definitions.values.each do |metric|
        next if metric.attributes[:milestone] != milestone || metric.attributes[:status] != 'implemented'

        metric.attributes[:status] = 'data_available'
        path = metric.path
        File.open(path, "w") { |file| file << metric.to_h.deep_stringify_keys.to_yaml }
      end

      puts "Task completed successfully"
    end
  end
end
