RSpec.configure do |config|
  config.before(:each, :elastic) do
    Gitlab::Elastic::Helper.create_empty_index
  end

  config.after(:each, :elastic) do
    Gitlab::Elastic::Helper.delete_index
  end
end
