# frozen_string_literal: true

RSpec.describe "orchestrator" do
  it "runs executable" do
    expect(`bundle exec exe/orchestrator`).to(
      match(/orchestrator create \[SUBCOMMAND\]/)
        .and(match(/orchestrator destroy \[SUBCOMMAND\]/))
        .and(match(/orchestrator doctor/))
        .and(match(/orchestrator help \[COMMAND\]/))
        .and(match(/orchestrator log \[SUBCOMMAND\]/))
        .and(match(/orchestrator version/))
        .and(match(/Options:\s+\[--force-color\], \[--no-force-color\], \[--skip-force-color\]/))
    )
  end
end
