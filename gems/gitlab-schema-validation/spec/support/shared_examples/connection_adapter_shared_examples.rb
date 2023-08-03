# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'connection adapter' do
  subject(:connection) { described_class.new(connection_object) }

  let(:connection_class) { class_double(Class, name: connection_class_name) }
  let(:connection_object) { instance_double(connection_class_name, class: connection_class) }
  let(:adapter) do
    instance_double(
      described_class::CONNECTION_ADAPTERS[connection_class_name],
      current_schema: schema,
      exec_query: query_result,
      select_rows: rows
    )
  end

  before do
    allow(connection).to receive(:connection_adapter).and_return(adapter)
  end

  context 'when using a valid connection adapter' do
    describe '#current_schema' do
      it { expect(connection.current_schema).to eq(schema) }
    end

    describe '#select_rows' do
      it { expect(connection.select_rows(sql, schemas)).to eq(rows) }
    end

    describe '#exec_query' do
      it { expect(connection.exec_query(sql, schemas)).to eq(query_result) }
    end
  end
end
