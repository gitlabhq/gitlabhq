# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ProjectArchivedEvent do
  subject(:constructor) { described_class.new(data: data) }

  where(:data, :valid) do
    valid_event = {
      project_id: 1,
      namespace_id: 2,
      root_namespace_id: 3
    }

    # All combinations of missing keys
    with_missing_keys = 0.upto(valid_event.size - 1)
      .flat_map { |size| valid_event.keys.combination(size).to_a }
      .map { |keys| [valid_event.slice(*keys), false] }

    [
      [valid_event, true],
      *with_missing_keys,
      [{ project_id: 'foo', namespace_id: 2 }, false],
      [{ project_id: 1, namespace_id: 'foo' }, false],
      [{ project_id: [], namespace_id: 2 }, false],
      [{ project_id: 1, namespace_id: [] }, false],
      [{ project_id: {}, namespace_id: 2 }, false],
      [{ project_id: 1, namespace_id: {} }, false],
      ['foo', false],
      [123, false],
      [[], false]
    ]
  end

  with_them do
    it 'validates data' do
      if valid
        expect { constructor }.not_to raise_error
      else
        expect { constructor }.to raise_error(Gitlab::EventStore::InvalidEvent)
      end
    end
  end
end
