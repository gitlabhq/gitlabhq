# frozen_string_literal: true

require 'spec_helper'

# Ratchet spec: fails CI if a new Resolvers::Search:: resolver omits the rate limit (gap closed after #517757).
RSpec.describe 'Resolvers::Search:: resolvers are rate limited', :eager_load, feature_category: :global_search do
  let(:search_namespace_resolver_classes) do
    ObjectSpace.each_object(Class).select { |klass| search_namespace_resolver?(klass) }
  end

  # ObjectSpace.each_object(Class) walks every live Class (rescue covers one that raises on
  # `<`/`.name`); BaseResolver itself is excluded so it can't satisfy "finds at least one
  # resolver" on its own if every real subclass stopped matching.
  def search_namespace_resolver?(klass)
    name = klass.name
    name.present? && name.start_with?('Resolvers::Search::') && (klass < ::Resolvers::BaseResolver) &&
      klass != ::Resolvers::Search::BaseResolver
  rescue StandardError, ScriptError
    false
  end

  # Skipped on FOSS: every current Resolvers::Search:: resolver is EE-only, so this is
  # a regression guard against the namespace going empty under EE, not a CE requirement.
  it 'finds at least one resolver in the Resolvers::Search:: namespace', if: Gitlab.ee? do
    expect(search_namespace_resolver_classes).not_to be_empty
  end

  it 'includes Search::SearchRateLimitable in every Resolvers::Search:: resolver' do
    unlimited = search_namespace_resolver_classes.reject { |klass| klass.include?(::Search::SearchRateLimitable) }

    expect(unlimited).to be_empty,
      "these resolvers must include Search::SearchRateLimitable (directly or via " \
        "Resolvers::Search::BaseResolver): #{unlimited.map(&:name).join(', ')}"
  end

  it 'actually enforces the rate limit when ready? runs, not merely includes the module' do
    not_enforced = search_namespace_resolver_classes.select do |klass|
      instance = klass.allocate
      rate_limit_called = false
      allow(instance).to receive(:verify_search_rate_limit!) { rate_limit_called = true }
      allow(instance).to receive_messages(
        current_user: nil,
        context: { request: instance_double(ActionDispatch::Request, ip: '127.0.0.1') }
      )

      if instance.respond_to?(:verify_additional_preconditions!, true)
        allow(instance).to receive(:verify_additional_preconditions!)
      end

      begin
        instance.ready?
      rescue StandardError, ScriptError
        # A resolver may legitimately raise once it reaches real precondition checks; we only
        # care whether verify_search_rate_limit! was reached before that happened.
      end

      !rate_limit_called
    end

    expect(not_enforced).to be_empty,
      "these resolvers must call verify_search_rate_limit! from ready? (directly or via " \
        "super into Resolvers::Search::BaseResolver): #{not_enforced.map(&:name).join(', ')}"
  end
end
