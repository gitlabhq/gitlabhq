# frozen_string_literal: true

module Ci
  class UpdateBuildQueueService
    def execute(build)
      send_details(build)
      tick_for(build, build.project.all_runners)
      true
    end

    private

    def send_details(build)
      key = "builds:details:#{build.id}"
      value = build.details

      Gitlab::Workhorse::set_key_and_notify(key, value,
        expire: 5.minutes, overwrite: true,
        notification_channel: 'builds:notifications')
    end

    def tick_for(build, runners)
      runners.each do |runner|
        runner.pick_build!(build)
      end
    end
  end
end
