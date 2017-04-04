require 'spec_helper'

describe IssuablesHelper do
  let(:label)  { build_stubbed(:label) }
  let(:label2) { build_stubbed(:label) }

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
        expect(helper.issuables_state_counter_text(:issues, :opened)).
          to eq('<span>Open</span> <span class="badge">42</span>')
      end

      it 'returns "Closed" when state is :closed' do
        expect(helper.issuables_state_counter_text(:issues, :closed)).
          to eq('<span>Closed</span> <span class="badge">42</span>')
      end

      it 'returns "Merged" when state is :merged' do
        expect(helper.issuables_state_counter_text(:merge_requests, :merged)).
          to eq('<span>Merged</span> <span class="badge">42</span>')
      end

      it 'returns "All" when state is :all' do
        expect(helper.issuables_state_counter_text(:merge_requests, :all)).
          to eq('<span>All</span> <span class="badge">42</span>')
      end
    end

    describe 'counter caching based on issuable type and params', :caching do
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

      it 'returns the cached value when called for the same issuable type & with the same params' do
        expect(helper).to receive(:params).twice.and_return(params)
        expect(helper).to receive(:issuables_count_for_state).with(:issues, :opened).and_return(42)

        expect(helper.issuables_state_counter_text(:issues, :opened)).
          to eq('<span>Open</span> <span class="badge">42</span>')

        expect(helper).not_to receive(:issuables_count_for_state)

        expect(helper.issuables_state_counter_text(:issues, :opened)).
          to eq('<span>Open</span> <span class="badge">42</span>')
      end

      it 'does not take some keys into account in the cache key' do
        expect(helper).to receive(:params).and_return({
          author_id: '11',
          state: 'foo',
          sort: 'foo',
          utf8: 'foo',
          page: 'foo'
        }.with_indifferent_access)
        expect(helper).to receive(:issuables_count_for_state).with(:issues, :opened).and_return(42)

        expect(helper.issuables_state_counter_text(:issues, :opened)).
          to eq('<span>Open</span> <span class="badge">42</span>')

        expect(helper).to receive(:params).and_return({
          author_id: '11',
          state: 'bar',
          sort: 'bar',
          utf8: 'bar',
          page: 'bar'
        }.with_indifferent_access)
        expect(helper).not_to receive(:issuables_count_for_state)

        expect(helper.issuables_state_counter_text(:issues, :opened)).
          to eq('<span>Open</span> <span class="badge">42</span>')
      end

      it 'does not take params order into account in the cache key' do
        expect(helper).to receive(:params).and_return('author_id' => '11', 'state' => 'opened')
        expect(helper).to receive(:issuables_count_for_state).with(:issues, :opened).and_return(42)

        expect(helper.issuables_state_counter_text(:issues, :opened)).
          to eq('<span>Open</span> <span class="badge">42</span>')

        expect(helper).to receive(:params).and_return('state' => 'opened', 'author_id' => '11')
        expect(helper).not_to receive(:issuables_count_for_state)

        expect(helper.issuables_state_counter_text(:issues, :opened)).
          to eq('<span>Open</span> <span class="badge">42</span>')
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
end
