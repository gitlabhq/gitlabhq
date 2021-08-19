# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LfsPointersFinder do
  subject(:finder) { described_class.new(repository, path) }

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:repository) { project.repository }

  let(:path) { nil }

  describe '#execute' do
    subject { finder.execute }

    let(:expected_blob_id) { '0c304a93cb8430108629bbbcaa27db3343299bc0' }

    context 'when path has no LFS files' do
      it { is_expected.to eq([]) }
    end

    context 'when path points to LFS file' do
      let(:path) { 'files/lfs/lfs_object.iso' }

      it 'returns LFS blob ids' do
        is_expected.to eq([expected_blob_id])
      end
    end

    context 'when path points to directory with LFS files' do
      let(:path) { 'files/lfs/' }

      it 'returns LFS blob ids' do
        is_expected.to eq([expected_blob_id])
      end
    end

    context 'when repository is empty' do
      let(:project) { create(:project, :empty_repo) }

      it { is_expected.to eq([]) }
    end
  end
end
