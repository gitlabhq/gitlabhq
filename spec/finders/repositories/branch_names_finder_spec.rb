# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Repositories::BranchNamesFinder do
  let(:project) { create(:project, :repository) }

  let(:branch_names_finder) { described_class.new(project.repository, search: 'conflict-*') }

  describe '#execute' do
    subject(:execute) { branch_names_finder.execute }

    it 'filters branch names' do
      expect(execute).to contain_exactly(
        'conflict-binary-file',
        'conflict-resolvable',
        'conflict-contains-conflict-markers',
        'conflict-missing-side',
        'conflict-start',
        'conflict-non-utf8',
        'conflict-too-large'
      )
    end
  end
end
