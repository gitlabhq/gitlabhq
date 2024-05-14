# frozen_string_literal: true

namespace :grape do
  desc 'Print compiled grape routes'
  task routes: :environment do
    # Getting the source of the endpoints
    # https://forum.gitlab.com/t/corresponding-ruby-file-for-route-api-v4-jobs-request/16663
    API::API.routes.each do |route|
      puts "#{route.options[:method]} #{route.path} - #{route_description(route.options)}"
    end
  end

  def route_description(options)
    options[:settings][:description][:description] if options[:settings][:description]
  end
end
