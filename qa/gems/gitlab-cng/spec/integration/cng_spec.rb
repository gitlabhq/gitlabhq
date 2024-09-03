# frozen_string_literal: true

RSpec.describe "cng" do
  it "runs executable" do
    expect(`bundle exec exe/cng`).to(
      match(/cng create \[SUBCOMMAND\]/)
        .and(match(/cng destroy \[SUBCOMMAND\]/))
        .and(match(/cng doctor/))
        .and(match(/cng help \[COMMAND\]/))
        .and(match(/cng log \[SUBCOMMAND\]/))
        .and(match(/cng version/))
        .and(match(/Options:\s+\[--force-color\], \[--no-force-color\], \[--skip-force-color\]/))
    )
  end
end
