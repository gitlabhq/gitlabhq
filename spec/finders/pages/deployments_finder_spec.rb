# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pages::DeploymentsFinder, feature_category: :pages do
  # Most of Pages::DeploymentsFinder is tested with the GraphQL request specs
  # so this spec will only test remaining conditions that cannot be
  # tested otherwise.

  it 'execute throws an error when passed a parent that\'s not of type Project or Namespace' do
    expect { described_class.new("Foo").execute }.to raise_error(
      RuntimeError, "Pages::DeploymentsFinder only supports Namespace or Projects as parent"
    )
  end
end
