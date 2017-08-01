require 'yaml'

module Gitlab
  module SidekiqConfig
    def self.queues(rails_path = Rails.root.to_s, except: [])
      queues_file_path = File.join(rails_path, 'config', 'sidekiq_queues.yml')

      YAML.load_file(queues_file_path).fetch(:queues).map { |queue, _| queue } - except
    end
  end
end
