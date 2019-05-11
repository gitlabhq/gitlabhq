# frozen_string_literal: true
if Gitlab.ee?
  SeedFu.fixture_paths += %W[ee/db/fixtures ee/db/fixtures/#{Rails.env}]
end
