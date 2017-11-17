require 'spec_helper'

describe EpicsFinder do
  let(:user) { create(:user)  }
  let(:search_user) { create(:user)  }
  let(:group) { create(:group, :private) }
  let(:another_group) { create(:group) }
  let!(:epic1) { create(:epic, group: group, title: 'This is awesome epic', created_at: 1.week.ago) }
  let!(:epic2) { create(:epic, group: group, created_at: 4.days.ago, author: user) }
  let!(:epic3) { create(:epic, group: group, description: 'not so awesome') }
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

      context 'wtih correct params' do
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

        context 'by iids' do
          it 'returns all epics by the given iids' do
            expect(epics(iids: [epic1.iid, epic3.iid])).to contain_exactly(epic1, epic3)
          end
        end
      end
    end
  end
end
