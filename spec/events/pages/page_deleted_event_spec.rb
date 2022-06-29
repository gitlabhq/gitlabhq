# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pages::PageDeletedEvent do
  where(:data, :valid) do
    [
      [{ project_id: 1, namespace_id: 2 }, true],
      [{ project_id: 1, namespace_id: 2, root_namespace_id: 3 }, true],
      [{ project_id: 1 }, false],
      [{ namespace_id: 1 }, false],
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
      constructor = -> { described_class.new(data: data) }

      if valid
        expect { constructor.call }.not_to raise_error
      else
        expect { constructor.call }.to raise_error(Gitlab::EventStore::InvalidEvent)
      end
    end
  end
end
