# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Create security training providers in production' do
  subject { load Rails.root.join('db', 'fixtures', 'production', '005_add_security_training_providers.rb') }

  it_behaves_like 'security training providers importer'
end
