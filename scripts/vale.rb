#!/usr/bin/env ruby
#
# Get the JSON output from Vale and format it in a nicer way
# See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/46725
#
# Usage:
#   vale --output=JSON filename.md | ruby vale.rb
#

require 'json'

input = ARGF.read
data = JSON.parse(input)

data.each_pair do |source, alerts|
  alerts.each do |alert|
    puts "#{source}:"
    puts " Line #{alert['Line']}, position #{alert['Span'][0]} (rule #{alert['Check']})"
    puts " #{alert['Severity']}: #{alert['Message']}"
    puts " More information: #{alert['Link']}"
    puts
  end
end
