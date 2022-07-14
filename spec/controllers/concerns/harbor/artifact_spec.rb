# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Harbor::Artifact do
  controller(ActionController::Base) do
    include ::Harbor::Artifact
  end
  it_behaves_like 'raises NotImplementedError when calling #container'
end
