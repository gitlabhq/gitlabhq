# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Notes::RepositionImageDiffNote do
  include GraphqlHelpers

  describe '#resolve' do
    subject do
      mutation.resolve(note: note, position: new_position)
    end

    let_it_be(:noteable) { create(:merge_request) }
    let_it_be(:project) { noteable.project }

    let(:note) { create(:image_diff_note_on_merge_request, noteable: noteable, project: project) }

    let(:mutation) do
      described_class.new(object: nil, context: query_context, field: nil)
    end

    let(:new_position) do
      { x: 10, y: 11, width: 12, height: 13 }
    end

    context 'when the user does not have permission' do
      let(:current_user) { nil }

      it 'raises an error if the resource is not accessible to the user' do
        expect { subject }.to raise_error(
          Gitlab::Graphql::Errors::ResourceNotAvailable,
          Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR
        )
      end
    end

    context 'when the user has permission' do
      let(:current_user) { project.creator }
      let(:mutated_note) { subject[:note] }
      let(:errors) { subject[:errors] }

      it 'mutates the note', :aggregate_failures do
        expect { subject }.to change { note.reset.position.to_h }.to(include(new_position))

        expect(mutated_note).to eq(note)
        expect(errors).to be_empty
      end

      context 'when the note is a DiffNote, but not on an image' do
        let(:note) { create(:diff_note_on_merge_request, noteable: noteable, project: project) }

        it 'raises an error' do
          expect { subject }.to raise_error(
            Gitlab::Graphql::Errors::ResourceNotAvailable,
            'Resource is not an ImageDiffNote'
          )
        end
      end
    end
  end
end
