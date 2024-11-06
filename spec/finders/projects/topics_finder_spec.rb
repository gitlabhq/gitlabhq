# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::TopicsFinder, :with_current_organization do
  let_it_be(:namespace) { create(:namespace, organization: current_organization) }
  let_it_be(:user) { create(:user, namespace: namespace) }

  let_it_be(:topic1) { create(:topic, name: 'topicB', organization: current_organization) }
  let_it_be(:topic2) { create(:topic, name: 'topicC', organization: current_organization) }
  let_it_be(:topic3) { create(:topic, name: 'topicA', organization: current_organization) }

  let_it_be(:project1) { create(:project, :public, namespace: user.namespace, topic_list: 'topicC, topicA, topicB') }
  let_it_be(:project2) { create(:project, :public, namespace: user.namespace, topic_list: 'topicC, topicA') }
  let_it_be(:project3) { create(:project, :public, namespace: user.namespace, topic_list: 'topicC') }

  describe '#execute' do
    it 'returns topics' do
      topics = described_class.new(organization_id: current_organization.id).execute

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
          topics = described_class.new(params: { search: search }, organization_id: current_organization.id).execute

          expect(topics.map(&:name)).to eq(result)
        end
      end
    end

    context 'filter by without_projects' do
      let_it_be(:topic4) { create(:topic, name: 'unassigned topic', organization: current_organization) }

      it 'returns topics without assigned projects' do
        topics = described_class.new(
          params: { without_projects: true }, organization_id: current_organization.id
        ).execute

        expect(topics).to contain_exactly(topic4)
      end

      it 'returns topics without assigned projects' do
        topics = described_class.new(
          params: { without_projects: false }, organization_id: current_organization.id
        ).execute

        expect(topics).to contain_exactly(topic1, topic2, topic3, topic4)
      end
    end
  end
end
