require 'spec_helper'

describe IssuablesHelper do
  let(:label)  { build_stubbed(:label) }
  let(:label2) { build_stubbed(:label) }

  describe '#users_dropdown_label' do
    let(:user)  { build_stubbed(:user) }
    let(:user2)  { build_stubbed(:user) }

    it 'returns unassigned' do
      expect(users_dropdown_label([])).to eq('Unassigned')
    end

    it 'returns selected user\'s name' do
      expect(users_dropdown_label([user])).to eq(user.name)
    end

    it 'returns selected user\'s name and counter' do
      expect(users_dropdown_label([user, user2])).to eq("#{user.name} + 1 more")
    end
  end

  describe '#issuable_labels_tooltip' do
    it 'returns label text' do
      expect(issuable_labels_tooltip([label])).to eq(label.title)
    end

    it 'returns label text' do
      expect(issuable_labels_tooltip([label, label2], limit: 1)).to eq("#{label.title}, and 1 more")
    end
  end

  describe '#issuables_state_counter_text' do
    let(:user) { create(:user) }

    describe 'state text' do
      before do
        allow(helper).to receive(:issuables_count_for_state).and_return(42)
      end

      it 'returns "Open" when state is :opened' do
        expect(helper.issuables_state_counter_text(:issues, :opened))
          .to eq('<span>Open</span> <span class="badge">42</span>')
      end

      it 'returns "Closed" when state is :closed' do
        expect(helper.issuables_state_counter_text(:issues, :closed))
          .to eq('<span>Closed</span> <span class="badge">42</span>')
      end

      it 'returns "Merged" when state is :merged' do
        expect(helper.issuables_state_counter_text(:merge_requests, :merged))
          .to eq('<span>Merged</span> <span class="badge">42</span>')
      end

      it 'returns "All" when state is :all' do
        expect(helper.issuables_state_counter_text(:merge_requests, :all))
          .to eq('<span>All</span> <span class="badge">42</span>')
      end
    end

    describe 'counter caching based on issuable type and params', :use_clean_rails_memory_store_caching do
      let(:params) do
        {
          scope: 'created-by-me',
          state: 'opened',
          utf8: '✓',
          author_id: '11',
          assignee_id: '18',
          label_name: %w(bug discussion documentation),
          milestone_title: 'v4.0',
          sort: 'due_date_asc',
          namespace_id: 'gitlab-org',
          project_id: 'gitlab-ce',
          page: 2
        }.with_indifferent_access
      end

      let(:issues_finder) { IssuesFinder.new(nil, params) }
      let(:merge_requests_finder) { MergeRequestsFinder.new(nil, params) }

      before do
        allow(helper).to receive(:issues_finder).and_return(issues_finder)
        allow(helper).to receive(:merge_requests_finder).and_return(merge_requests_finder)
      end

      it 'returns the cached value when called for the same issuable type & with the same params' do
        expect(issues_finder).to receive(:count_by_state).and_return(opened: 42)

        expect(helper.issuables_state_counter_text(:issues, :opened))
          .to eq('<span>Open</span> <span class="badge">42</span>')

        expect(issues_finder).not_to receive(:count_by_state)

        expect(helper.issuables_state_counter_text(:issues, :opened))
          .to eq('<span>Open</span> <span class="badge">42</span>')
      end

      it 'takes confidential status into account when searching for issues' do
        expect(issues_finder).to receive(:count_by_state).and_return(opened: 42)

        expect(helper.issuables_state_counter_text(:issues, :opened))
          .to include('42')

        expect(issues_finder).to receive(:user_cannot_see_confidential_issues?).twice.and_return(false)
        expect(issues_finder).to receive(:count_by_state).and_return(opened: 40)

        expect(helper.issuables_state_counter_text(:issues, :opened))
          .to include('40')

        expect(issues_finder).to receive(:user_can_see_all_confidential_issues?).and_return(true)
        expect(issues_finder).to receive(:count_by_state).and_return(opened: 45)

        expect(helper.issuables_state_counter_text(:issues, :opened))
          .to include('45')
      end

      it 'does not take confidential status into account when searching for merge requests' do
        expect(merge_requests_finder).to receive(:count_by_state).and_return(opened: 42)
        expect(merge_requests_finder).not_to receive(:user_cannot_see_confidential_issues?)
        expect(merge_requests_finder).not_to receive(:user_can_see_all_confidential_issues?)

        expect(helper.issuables_state_counter_text(:merge_requests, :opened))
          .to include('42')
      end

      it 'does not take some keys into account in the cache key' do
        expect(issues_finder).to receive(:count_by_state).and_return(opened: 42)
        expect(issues_finder).to receive(:params).and_return({
          author_id: '11',
          state: 'foo',
          sort: 'foo',
          utf8: 'foo',
          page: 'foo'
        }.with_indifferent_access)

        expect(helper.issuables_state_counter_text(:issues, :opened))
          .to eq('<span>Open</span> <span class="badge">42</span>')

        expect(issues_finder).not_to receive(:count_by_state)
        expect(issues_finder).to receive(:params).and_return({
          author_id: '11',
          state: 'bar',
          sort: 'bar',
          utf8: 'bar',
          page: 'bar'
        }.with_indifferent_access)

        expect(helper.issuables_state_counter_text(:issues, :opened))
          .to eq('<span>Open</span> <span class="badge">42</span>')
      end

      it 'does not take params order into account in the cache key' do
        expect(issues_finder).to receive(:params).and_return('author_id' => '11', 'state' => 'opened')
        expect(issues_finder).to receive(:count_by_state).and_return(opened: 42)

        expect(helper.issuables_state_counter_text(:issues, :opened))
          .to eq('<span>Open</span> <span class="badge">42</span>')

        expect(issues_finder).to receive(:params).and_return('state' => 'opened', 'author_id' => '11')
        expect(issues_finder).not_to receive(:count_by_state)

        expect(helper.issuables_state_counter_text(:issues, :opened))
          .to eq('<span>Open</span> <span class="badge">42</span>')
      end
    end
  end

  describe '#issuable_reference' do
    context 'when show_full_reference truthy' do
      it 'display issuable full reference' do
        assign(:show_full_reference, true)
        issue = build_stubbed(:issue)

        expect(helper.issuable_reference(issue)).to eql(issue.to_reference(full: true))
      end
    end

    context 'when show_full_reference falsey' do
      context 'when @group present' do
        it 'display issuable reference to @group' do
          project = build_stubbed(:project)

          assign(:show_full_reference, nil)
          assign(:group, project.namespace)

          issue = build_stubbed(:issue)

          expect(helper.issuable_reference(issue)).to eql(issue.to_reference(project.namespace))
        end
      end

      context 'when @project present' do
        it 'display issuable reference to @project' do
          project = build_stubbed(:project)

          assign(:show_full_reference, nil)
          assign(:group, nil)
          assign(:project, project)

          issue = build_stubbed(:issue)

          expect(helper.issuable_reference(issue)).to eql(issue.to_reference(project))
        end
      end
    end
  end

  describe '#issuable_filter_present?' do
    it 'returns true when any key is present' do
      allow(helper).to receive(:params).and_return(
        ActionController::Parameters.new(milestone_title: 'Velit consectetur asperiores natus delectus.',
                                         project_id: 'gitlabhq',
                                         scope: 'all')
      )

      expect(helper.issuable_filter_present?).to be_truthy
    end

    it 'returns false when no key is present' do
      allow(helper).to receive(:params).and_return(
        ActionController::Parameters.new(project_id: 'gitlabhq',
                                         scope: 'all')
      )

      expect(helper.issuable_filter_present?).to be_falsey
    end
  end

  describe '#updated_at_by' do
    let(:user) { create(:user) }
    let(:unedited_issuable) { create(:issue) }
    let(:edited_issuable) { create(:issue, last_edited_by: user, created_at: 3.days.ago, updated_at: 2.days.ago, last_edited_at: 2.days.ago) }
    let(:edited_updated_at_by) do
      {
        updatedAt: edited_issuable.updated_at.to_time.iso8601,
        updatedBy: {
          name: user.name,
          path: user_path(user)
        }
      }
    end

    it { expect(helper.updated_at_by(unedited_issuable)).to eq({}) }
    it { expect(helper.updated_at_by(edited_issuable)).to eq(edited_updated_at_by) }

    context 'when updated by a deleted user' do
      let(:edited_updated_at_by) do
        {
          updatedAt: edited_issuable.updated_at.to_time.iso8601,
          updatedBy: {
            name: User.ghost.name,
            path: user_path(User.ghost)
          }
        }
      end

      before do
        user.destroy
      end

      it 'returns "Ghost user" as edited_by' do
        expect(helper.updated_at_by(edited_issuable.reload)).to eq(edited_updated_at_by)
      end
    end
  end
end
