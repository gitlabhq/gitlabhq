# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::TopicsHelper, feature_category: :groups_and_projects do
  describe '#topic_explore_projects_cleaned_path' do
    using RSpec::Parameterized::TableSyntax

    where(:topic_name, :expected_path) do
      [
        %w[cat /explore/projects/topics/cat],
        %w[cat🐈emoji /explore/projects/topics/cat%25F0%259F%2590%2588emoji],
        %w[cat/mouse /explore/projects/topics/cat%252Fmouse],
        ['cat space', '/explore/projects/topics/cat+space']
      ]
    end

    with_them do
      subject(:path) { topic_explore_projects_cleaned_path(topic_name: topic_name) }

      it { is_expected.to eq(expected_path) }
    end

    context 'when explore_topics_cleaned_path feature flag is disabled' do
      before do
        stub_feature_flags(explore_topics_cleaned_path: false)
      end

      it 'does no cleaning' do
        expect(topic_explore_projects_cleaned_path(topic_name: 'cat/mouse'))
          .to eq('/explore/projects/topics/cat%2Fmouse')
      end
    end
  end
end
