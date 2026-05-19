# frozen_string_literal: true

require 'fast_spec_helper'

# Stub Packages::Package.package_types since it is an ActiveRecord enum
# not available under fast_spec_helper
module Packages
  class Package
    PACKAGE_TYPES = {
      'maven' => 1, 'npm' => 2, 'conan' => 3, 'nuget' => 4, 'pypi' => 5,
      'composer' => 6, 'generic' => 7, 'golang' => 8, 'debian' => 9,
      'rubygems' => 10, 'helm' => 11, 'terraform_module' => 12, 'rpm' => 13,
      'ml_model' => 14, 'cargo' => 15
    }.freeze

    def self.package_types
      PACKAGE_TYPES
    end
  end
end

require_relative '../../../app/events/packages/package_created_event'
require_relative '../../support/shared_examples/events/event_with_schema_shared_examples'

RSpec.describe Packages::PackageCreatedEvent, feature_category: :package_registry do
  it_behaves_like 'an event with schema',
    valid_data: { project_id: 1, id: 2, name: 'my-package', package_type: 'npm' },
    missing_required: %i[project_id name package_type id],
    invalid_types: { project_id: 'not_an_integer', package_type: 'invalid_type' }

  describe '#schema' do
    let(:valid_data) { { project_id: 1, id: 2, name: 'my-package', package_type: 'npm' } }

    context 'with valid optional version' do
      it 'accepts a string' do
        data = valid_data.merge(version: '1.0.0')

        expect { described_class.new(data: data) }.not_to raise_error
      end

      it 'accepts null' do
        data = valid_data.merge(version: nil)

        expect { described_class.new(data: data) }.not_to raise_error
      end
    end
  end
end
