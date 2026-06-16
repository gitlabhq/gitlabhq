# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/gitlab/principles_distiller/graphql_client'

RSpec.describe Gitlab::PrinciplesDistiller::GraphqlClient do
  subject(:run_query) { client.query(query, variables) }

  let(:client) { described_class.new(host: 'https://gitlab.example', token: 'token') }
  let(:query) { 'query { project { id } }' }
  let(:variables) { {} }
  let(:fake_response) { instance_double(Net::HTTPResponse, code: '200', body: response_body) }
  let(:captured_request) { [] }
  let(:http_instance) { instance_double(Net::HTTP) }

  before do
    allow(Net::HTTP).to receive(:new).and_return(http_instance)
    allow(http_instance).to receive(:use_ssl=)
    allow(http_instance).to receive(:read_timeout=)
    allow(http_instance).to receive(:request) do |request|
      captured_request << request
      allow(fake_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(http_success)
      fake_response
    end
  end

  context 'with a successful response' do
    let(:http_success) { true }
    let(:response_body) { '{"data":{"project":{"id":"gid://gitlab/Project/1"}}}' }

    it { is_expected.to eq('project' => { 'id' => 'gid://gitlab/Project/1' }) }

    it 'sends the bearer token in the Authorization header' do
      run_query

      expect(captured_request.first['Authorization']).to eq('Bearer token')
    end

    context 'with variables' do
      let(:variables) { { foo: 'bar' } }

      it 'sends the query+variables as JSON in the body' do
        run_query

        body = JSON.parse(captured_request.first.body)
        expect(body).to eq('query' => query, 'variables' => { 'foo' => 'bar' })
      end
    end
  end

  context 'with a non-2xx response' do
    let(:http_success) { false }
    let(:response_body) { 'Internal Server Error' }

    before do
      allow(fake_response).to receive(:code).and_return('500')
    end

    it 'raises Error with status and body' do
      expect { run_query }.to raise_error(described_class::Error, /500/)
    end
  end

  context 'with an errors array in the body' do
    let(:http_success) { true }
    let(:response_body) { '{"errors":[{"message":"unauthorized"},{"message":"oh no"}]}' }

    it 'raises Error joining the messages' do
      expect { run_query }.to raise_error(described_class::Error, /unauthorized; oh no/)
    end
  end

  context 'when host has a trailing slash' do
    let(:http_success) { true }
    let(:response_body) { '{"data":null}' }
    let(:client) { described_class.new(host: 'https://gitlab.example/', token: 'token') }
    let(:query) { 'query { ping }' }

    it 'normalizes the host so the URL is not constructed with a double slash' do
      run_query

      expect(captured_request.first.uri.to_s).to eq('https://gitlab.example/api/graphql')
    end
  end
end
