# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::TopicsFinder do
  let_it_be(:user) { create(:user) }

  let!(:topic1) { create(:topic, name: 'topicB') }
  let!(:topic2) { create(:topic, name: 'topicC') }
  let!(:topic3) { create(:topic, name: 'topicA') }

  let!(:project1) { create(:project, :public, namespace: user.namespace, topic_list: 'topicC, topicA, topicB') }
  let!(:project2) { create(:project, :public, namespace: user.namespace, topic_list: 'topicC, topicA') }
  let!(:project3) { create(:project, :public, namespace: user.namespace, topic_list: 'topicC') }

  describe '#execute' do
    it 'returns topics' do
      topics = described_class.new.execute

      expect(topics).to eq([topic2, topic3, topic1])
    end

    context 'filter by name' do
      using RSpec::Parameterized::TableSyntax

      where(:search, :result) do
        'topic'  | %w[topicC topicA topicB]
        'pic'    | %w[topicC topicA topicB]
        'B'      | %w[]
        'cB'     | %w[]
        'icB'    | %w[topicB]
        'topicA' | %w[topicA]
        'topica' | %w[topicA]
      end

      with_them do
        it 'returns filtered topics' do
          topics = described_class.new(params: { search: search }).execute

          expect(topics.map(&:name)).to eq(result)
        end
      end
    end
  end
end
