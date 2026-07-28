# frozen_string_literal: true

namespace :gitlab do
  namespace :mcp do
    desc 'GitLab | MCP | Verify MCP server setup'
    task :verify_setup, [:username] => :gitlab_environment do |_, args|
      Gitlab::Mcp::Administration::VerifyMcpServerSetup.new(args[:username]).execute
    end
  end
end
