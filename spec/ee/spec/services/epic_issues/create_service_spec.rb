require 'spec_helper'

describe EpicIssues::CreateService do
  describe '#execute' do
    let(:group) { create :group }
    let(:epic) { create :epic, group: group }
    let(:project) { create(:project, group: group) }
    let(:issue) { create :issue, project: project }
    let(:user) { create :user }
    let(:reference) { issue.to_reference(full: true) }
    let(:params) do
      {}
    end

    subject { described_class.new(epic, user, params).execute }

    context 'when user has permissions to link the issue' do
      before do
        group.add_developer(user)
      end

      context 'when the reference list is empty' do
        let(:params) do
          { issue_references: [] }
        end

        it 'returns error' do
          is_expected.to eq(message: 'No Issue found for given params', status: :error, http_status: 404)
        end
      end

      context 'when there is an issue to relate' do
        context 'when shortcut for Issue is given' do
          let(:params) do
            { issue_references: [issue.to_reference] }
          end

          it 'returns error' do
            is_expected.to eq(message: 'No Issue found for given params', status: :error, http_status: 404)
          end

          it 'no relationship is created' do
            expect { subject }.not_to change { EpicIssue.count }
          end
        end

        context 'when a full reference is given' do
          let(:params) do
            { issue_references: [reference] }
          end

          it 'creates relationships' do
            expect { subject }.to change(EpicIssue, :count).from(0).to(1)

            expect(EpicIssue.find_by!(issue_id: issue.id)).to have_attributes(epic: epic)
          end

          it 'returns success status' do
            is_expected.to eq(status: :success)
          end
        end

        context 'when an issue links is given' do
          let(:params) do
            { issue_references: [IssuesHelper.url_for_issue(issue.iid, issue.project)] }
          end

          it 'creates relationships' do
            expect { subject }.to change(EpicIssue, :count).from(0).to(1)

            expect(EpicIssue.find_by!(issue_id: issue.id)).to have_attributes(epic: epic)
          end

          it 'returns success status' do
            is_expected.to eq(status: :success)
          end
        end
      end
    end

    context 'when user does not have permissions to link the issue' do
      let(:params) do
        { issue_references: [reference] }
      end

      it 'returns error' do
        is_expected.to eq(message: 'No Issue found for given params', status: :error, http_status: 404)
      end

      it 'no relationship is created' do
        expect { subject }.not_to change { EpicIssue.count }
      end
    end

    context 'when an issue is already assigned to another epic' do
      let(:params) do
        { issue_references: [reference] }
      end

      before do
        group.add_developer(user)
        create(:epic_issue, epic: epic, issue: issue)
      end

      let(:another_epic) { create(:epic, group: group) }

      subject { described_class.new(another_epic, user, params).execute }

      it 'does not create a new association' do
        expect { subject }.not_to change(EpicIssue, :count).from(1)
      end

      it 'updates the existing association' do
        expect { subject }.to change { EpicIssue.find_by!(issue_id: issue.id).epic }.from(epic).to(another_epic)
      end

      it 'returns success status' do
        is_expected.to eq(status: :success)
      end
    end

    context 'when issue from non group project is given' do
      let(:another_issue) { create :issue }

      let(:params) do
        { issue_references: [another_issue.to_reference(full: true)] }
      end

      before do
        group.add_developer(user)
        another_issue.project.add_developer(user)
      end

      it 'returns error' do
        is_expected.to eq(message: 'No Issue found for given params', status: :error, http_status: 404)
      end

      it 'no relationship is created' do
        expect { subject }.not_to change { EpicIssue.count }
      end
    end
  end
end
