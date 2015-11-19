require 'spec_helper'

describe IssuesFinder, benchmark: true do
  describe '#execute' do
    let(:user) { create(:user) }
    let(:project) { create(:project, :public) }

    let(:label1) { create(:label, project: project, title: 'A') }
    let(:label2) { create(:label, project: project, title: 'B') }

    before do
      10.times do |n|
        issue = create(:issue, author: user, project: project)

        if n > 4
          create(:label_link, label: label1, target: issue)
          create(:label_link, label: label2, target: issue)
        end
      end
    end

    describe 'retrieving issues without labels' do
      let(:finder) do
        IssuesFinder.new(user, scope: 'all', label_name: Label::None.title,
                               state: 'opened')
      end

      benchmark_subject { finder.execute }

      it { is_expected.to iterate_per_second(2000) }
    end

    describe 'retrieving issues with labels' do
      let(:finder) do
        IssuesFinder.new(user, scope: 'all', label_name: label1.title,
                               state: 'opened')
      end

      benchmark_subject { finder.execute }

      it { is_expected.to iterate_per_second(1000) }
    end

    describe 'retrieving issues for a single project' do
      let(:finder) do
        IssuesFinder.new(user, scope: 'all', label_name: Label::None.title,
                               state: 'opened', project_id: project.id)
      end

      benchmark_subject { finder.execute }

      it { is_expected.to iterate_per_second(2000) }
    end
  end
end
