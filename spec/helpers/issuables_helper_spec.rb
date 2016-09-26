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
          'scope' => 'created-by-me',
          'state' => 'opened',
          'utf8' => '✓',
          'author_id' => '11',
          'assignee_id' => '18',
          'label_name' => ['bug', 'discussion', 'documentation'],
          'milestone_title' => 'v4.0',
          'sort' => 'due_date_asc',
          'namespace_id' => 'gitlab-org',
          'project_id' => 'gitlab-ce',
          'page' => 2
        }
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

      describe 'keys not taken in account in the cache key' do
        %w[state sort utf8 page].each do |param|
          it "does not take in account params['#{param}'] in the cache key" do
            expect(helper).to receive(:params).and_return('author_id' => '11', param => 'foo')
            expect(helper).to receive(:issuables_count_for_state).with(:issues, :opened).and_return(42)

            expect(helper.issuables_state_counter_text(:issues, :opened)).
              to eq('<span>Open</span> <span class="badge">42</span>')

            expect(helper).to receive(:params).and_return('author_id' => '11', param => 'bar')
            expect(helper).not_to receive(:issuables_count_for_state)

            expect(helper.issuables_state_counter_text(:issues, :opened)).
              to eq('<span>Open</span> <span class="badge">42</span>')
          end
        end
      end

      it 'does not take params order in acount in the cache key' do
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
end
