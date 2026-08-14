# frozen_string_literal: true

class OrderedIntegrationsExperiment < ApplicationExperiment
  def self.context_keys = %i[actor]

  control
  variant(:candidate)

  # This is deprecated logic as of v0.6.0 and should eventually be removed, but
  # needs to stay intact while this experiment is running. The new strategy
  # utilizes Digest::SHA2, a secret seed, and generates a 64-byte string.
  #
  # https://gitlab.com/gitlab-org/gitlab/-/issues/334590
  #
  # @deprecated
  def key_for(source, seed = name)
    source = source.keys + source.values if source.is_a?(Hash)
    Digest::MD5.hexdigest(Array(source).map { |v| identify(v) }.unshift(seed).join('|')) # rubocop:disable Fips/MD5 -- Legacy context keys for a running experiment
  end

  private

  def control_behavior; end
  def candidate_behavior; end
end
