require 'spec_helper'

describe EpicsFinder do
  let(:user) { create(:user)  }
  let(:search_user) { create(:user)  }
  let(:group) { create(:group, :private) }
  let(:another_group) { create(:group) }
  let!(:epic1) { create(:epic, group: group, title: 'This is awesome epic', created_at: 1.week.ago) }
  let!(:epic2) { create(:epic, group: group, created_at: 4.days.ago, author: user, start_date: 2.days.ago) }
  let!(:epic3) { create(:epic, group: group, description: 'not so awesome', start_date: 5.days.ago, end_date: 3.days.ago) }
  let!(:epic4) { create(:epic, group: another_group) }

  describe '#execute' do
    def epics(params = {})
      params[:group_id] = group.id

      described_class.new(search_user, params).execute
    end

    context 'when epics feature is disabled' do
      before do
        group.add_developer(search_user)
      end

      it 'raises an exception' do
        expect { described_class.new(search_user).execute }.to raise_error { ArgumentError }
      end
    end

    context 'when epics feature is enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      context 'without param' do
        it 'raises an error when group_id param is missing' do
          expect { described_class.new(search_user).execute }.to raise_error { ArgumentError }
        end
      end

      context 'when user can not read epics of a group' do
        it 'raises an error when group_id param is missing' do
          expect { epics }.to raise_error { ArgumentError }
        end
      end

      context 'with correct params' do
        before do
          group.add_developer(search_user)
        end

        it 'returns all epics that belong to the given group' do
          expect(epics).to contain_exactly(epic1, epic2, epic3)
        end

        context 'by created_at' do
          it 'returns all epics created before the given date' do
            expect(epics(created_before: 2.days.ago)).to contain_exactly(epic1, epic2)
          end

          it 'returns all epics created after the given date' do
            expect(epics(created_after: 2.days.ago)).to contain_exactly(epic3)
          end

          it 'returns all epics created within the given interval' do
            expect(epics(created_after: 5.days.ago, created_before: 1.day.ago)).to contain_exactly(epic2)
          end
        end

        context 'by search' do
          it 'returns all epics that match the search' do
            expect(epics(search: 'awesome')).to contain_exactly(epic1, epic3)
          end
        end

        context 'by author' do
          it 'returns all epics authored by the given user' do
            expect(epics(author_id: user.id)).to contain_exactly(epic2)
          end
        end

        context 'by label' do
          let(:label) { create(:label) }
          let!(:labeled_epic) { create(:labeled_epic, group: group, labels: [label]) }

          it 'returns all epics with given label' do
            expect(epics(label_name: label.title)).to contain_exactly(labeled_epic)
          end
        end

        context 'when subgroups are supported', :nested_groups do
          let(:subgroup) { create(:group, :private, parent: group) }
          let(:subgroup2) { create(:group, :private, parent: subgroup) }
          let!(:subepic1) { create(:epic, group: subgroup) }
          let!(:subepic2) { create(:epic, group: subgroup2) }

          it 'returns all epics that belong to the given group and its subgroups' do
            expect(epics).to contain_exactly(epic1, epic2, epic3, subepic1, subepic2)
          end
        end

        context 'by timeframe' do
          it 'returns epics which start in the timeframe' do
            params = {
              start_date: 2.days.ago.strftime('%Y-%m-%d'),
              end_date: 1.day.ago.strftime('%Y-%m-%d')
            }

            expect(epics(params)).to contain_exactly(epic2)
          end

          it 'returns epics which end in the timeframe' do
            params = {
              start_date: 4.days.ago.strftime('%Y-%m-%d'),
              end_date: 3.days.ago.strftime('%Y-%m-%d')
            }

            expect(epics(params)).to contain_exactly(epic3)
          end

          it 'returns epics which start before and end after the timeframe' do
            params = {
              start_date: 4.days.ago.strftime('%Y-%m-%d'),
              end_date: 4.days.ago.strftime('%Y-%m-%d')
            }

            expect(epics(params)).to contain_exactly(epic3)
          end
        end
      end
    end
  end

  describe '#row_count' do
    let(:label) { create(:label) }
    let(:label2) { create(:label) }
    let!(:labeled_epic) { create(:labeled_epic, group: group, labels: [label]) }
    let!(:labeled_epic2) { create(:labeled_epic, group: group, labels: [label, label2]) }

    before do
      group.add_developer(search_user)
      stub_licensed_features(epics: true)
    end

    it 'returns number of rows when epics are grouped' do
      params = { group_id: group.id, label_name: [label.title, label2.title] }

      expect(described_class.new(search_user, params).row_count).to eq(1)
    end
  end
end
