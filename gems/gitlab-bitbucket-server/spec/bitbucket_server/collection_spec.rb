# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BitbucketServer::Collection do
  let(:connection) { instance_double(BitbucketServer::Connection) }
  let(:page) { 1 }
  let(:paginator) { BitbucketServer::Paginator.new(connection, 'http://more-data', :pull_request, page_offset: page) }

  subject { described_class.new(paginator) }

  describe '#current_page' do
    it 'returns 1' do
      expect(subject.current_page).to eq(1)
    end
  end

  describe '#prev_page' do
    it 'returns nil' do
      expect(subject.prev_page).to be_nil
    end
  end

  describe '#next_page' do
    it 'returns 2' do
      expect(subject.next_page).to eq(2)
    end
  end
end
