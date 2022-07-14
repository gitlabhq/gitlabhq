# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Harbor::Repository do
  controller(ActionController::Base) do
    include ::Harbor::Repository
  end
  it_behaves_like 'raises NotImplementedError when calling #container'
end
