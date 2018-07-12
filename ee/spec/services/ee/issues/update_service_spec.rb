require 'spec_helper'

describe Issues::UpdateService do
  let(:issue) { create(:issue) }
  let(:user) { issue.author }
  let(:project) { issue.project }

  describe 'execute' do
    def update_issue(opts)
      described_class.new(project, user, opts).execute(issue)
    end

    context 'refresh epic dates' do
      let(:epic) { create(:epic) }
      let(:issue) { create(:issue, epic: epic) }

      context 'updating milestone' do
        let(:milestone) { create(:milestone) }

        it 'calls epic#update_dates' do
          expect(epic).to receive(:update_dates).twice

          update_issue(milestone: milestone)
          update_issue(milestone_id: nil)
        end
      end

      context 'updating other fields' do
        it 'does not call epic#update_dates' do
          expect(epic).not_to receive(:update_dates)
          update_issue(title: 'foo')
        end
      end
    end
  end
end
