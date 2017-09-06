Spinach.hooks.before_scenario do
  allow(Gitlab::GitalyClient).to receive(:feature_enabled?).and_return(true)
end
