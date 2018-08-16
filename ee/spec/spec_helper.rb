Dir[Rails.root.join("ee/spec/support/helpers/*.rb")].each { |f| require f }
Dir[Rails.root.join("ee/spec/support/shared_contexts/*.rb")].each { |f| require f }
Dir[Rails.root.join("ee/spec/support/shared_examples/*.rb")].each { |f| require f }
Dir[Rails.root.join("ee/spec/support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.include EE::LicenseHelpers

  config.before(:all) do
    License.destroy_all # rubocop: disable DestroyAll
    TestLicense.init
  end

  config.around(:each, :geo) do |example|
    example.run if Gitlab::Database.postgresql?
  end

  config.around(:each, :geo_tracking_db) do |example|
    example.run if Gitlab::Geo.geo_database_configured?
  end
end
