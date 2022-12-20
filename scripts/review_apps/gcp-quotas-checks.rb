# frozen_string_literal: true

# We created this because we could not monitor k8s resource count directly in GCP monitoring (see
# https://gitlab.com/gitlab-org/quality/engineering-productivity-infrastructure/-/issues/37)
#
# If this functionality ever becomes available, please replace this script with GCP monitoring!

require 'json'

class QuotaChecker
  def initialize
    @exit_with_error = false
  end

  def check_quotas(quotas, threshold: 0.8)
    quotas.each do |quota|
      print "Checking quota #{quota['metric']}..."
      quota_percent_usage = quota['usage'].to_f / quota['limit']
      if quota_percent_usage > threshold
        puts "❌ #{quota['metric']} is above the #{threshold * 100}% threshold! (current value: #{quota_percent_usage})"
        @exit_with_error = true
      else
        puts "✅"
      end
    end
  end

  def failed?
    @exit_with_error
  end
end

quota_checker = QuotaChecker.new

puts "Checking regional quotas:"
gcloud_command_output = `gcloud compute regions describe us-central1 --format=json`
quotas = JSON.parse(gcloud_command_output)['quotas']
quota_checker.check_quotas(quotas)
puts

puts "Checking project-wide quotas:"
gcloud_command_output = `gcloud compute project-info describe --format=json`
quotas = JSON.parse(gcloud_command_output)['quotas']
quota_checker.check_quotas(quotas)

exit 1 if quota_checker.failed?
