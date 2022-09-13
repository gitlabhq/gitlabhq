# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Create security training providers in development' do
  subject { load Rails.root.join('db', 'fixtures', 'development', '044_add_security_training_providers.rb') }

  it_behaves_like 'security training providers importer'
end
