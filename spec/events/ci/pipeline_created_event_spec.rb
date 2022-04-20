# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineCreatedEvent do
  using RSpec::Parameterized::TableSyntax

  where(:data, :valid) do
    { pipeline_id: 1 }      | true
    { pipeline_id: nil }    | false
    { pipeline_id: "test" } | false
    {}                      | false
    { job_id: 1 }           | false
  end

  with_them do
    let(:event) { described_class.new(data: data) }

    it 'validates the data according to the schema' do
      if valid
        expect { event }.not_to raise_error
      else
        expect { event }.to raise_error(Gitlab::EventStore::InvalidEvent)
      end
    end
  end
end
