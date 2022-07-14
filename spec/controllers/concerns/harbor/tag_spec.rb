# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Harbor::Tag do
  controller(ActionController::Base) do
    include ::Harbor::Tag
  end
  it_behaves_like 'raises NotImplementedError when calling #container'
end
