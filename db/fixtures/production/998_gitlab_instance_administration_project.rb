# frozen_string_literal: true

response = ::Gitlab::DatabaseImporters::SelfMonitoring::Project::CreateService.new.execute

if response[:status] == :success
  puts "Successfully created self monitoring project."
else
  puts "Could not create self monitoring project due to error: '#{response[:message]}'"
  puts "Check logs for more details."
end
