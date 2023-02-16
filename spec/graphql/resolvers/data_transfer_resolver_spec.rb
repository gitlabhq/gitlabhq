# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::DataTransferResolver, feature_category: :source_code_management do
  include GraphqlHelpers

  describe '.source' do
    context 'with base DataTransferResolver' do
      it 'raises NotImplementedError' do
        expect { described_class.source }.to raise_error ::NotImplementedError
      end
    end

    context 'with projects DataTransferResolver' do
      let(:source) { described_class.project.source }

      it 'outputs "Project"' do
        expect(source).to eq 'Project'
      end
    end

    context 'with groups DataTransferResolver' do
      let(:source) { described_class.group.source }

      it 'outputs "Group"' do
        expect(source).to eq 'Group'
      end
    end
  end
end
