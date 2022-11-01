# frozen_string_literal: true

response = Sidekiq::Worker.skipping_transaction_check do
  result = ::Gitlab::DatabaseImporters::SelfMonitoring::Project::CreateService.new.execute

  next result unless result[:status] == :success

  AuthorizedProjectUpdate::ProjectRecalculateService.new(result[:project]).execute

  result
end

if response[:status] == :success
  puts "Successfully created self-monitoring project."
else
  puts "Could not create self-monitoring project due to error: '#{response[:message]}'"
  puts "Check logs for more details."
end
