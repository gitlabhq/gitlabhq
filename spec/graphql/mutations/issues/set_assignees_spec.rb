# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Issues::SetAssignees do
  it_behaves_like 'an assignable resource' do
    let_it_be(:resource, reload: true) { create(:issue) }
  end
end
