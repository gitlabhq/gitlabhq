# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::TopicsResolver do
  include GraphqlHelpers

  describe '#resolve' do
    let!(:topic1) { create(:topic, name: 'GitLab', non_private_projects_count: 1) }
    let!(:topic2) { create(:topic, name: 'git', non_private_projects_count: 2) }
    let!(:topic3) { create(:topic, name: 'topic3', non_private_projects_count: 3) }

    it 'finds all topics' do
      expect(resolve_topics).to eq([topic3, topic2, topic1])
    end

    context 'with search' do
      it 'searches environment by name' do
        expect(resolve_topics(search: 'git')).to eq([topic2, topic1])
      end

      context 'when the search term does not match any topic' do
        it 'is empty' do
          expect(resolve_topics(search: 'nonsense')).to be_empty
        end
      end
    end
  end

  def resolve_topics(args = {})
    resolve(described_class, args: args)
  end
end
