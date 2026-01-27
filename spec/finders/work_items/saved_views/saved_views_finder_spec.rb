# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::SavedViews::SavedViewsFinder, feature_category: :portfolio_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:other_user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:saved_view1) { create(:saved_view, namespace: group, name: 'SavedView1', author: user) }
  let_it_be(:saved_view2) { create(:saved_view, namespace: group, name: 'SavedView2', author: user) }
  let_it_be(:private_view) do
    create(:saved_view, namespace: group, name: 'PrivateView', author: other_user, private: true)
  end

  let_it_be(:other_namespace_view) { create(:saved_view) }

  let(:params) { {} }

  subject(:finder) { described_class.new(user: user, namespace: group, params: params).execute }

  describe '#execute' do
    it 'returns visible saved views for the namespace' do
      expect(finder).to contain_exactly(saved_view1, saved_view2)
    end

    context 'with id param' do
      let(:params) { { id: saved_view1.id } }

      it 'returns only the specified saved view' do
        expect(finder).to contain_exactly(saved_view1)
      end
    end

    context 'with search param' do
      context 'when having matching name' do
        let(:params) { { search: 'SavedView1' } }

        it 'returns saved views matching name' do
          expect(finder).to contain_exactly(saved_view1)
        end
      end

      context 'when having partial matching name' do
        let(:params) { { search: 'View1' } }

        it 'returns saved views partially matching name' do
          expect(finder).to contain_exactly(saved_view1)
        end
      end
    end

    context 'with subscribed_only param' do
      let!(:user_saved_view) { create(:user_saved_view, user: user, saved_view: saved_view1, namespace: group) }

      context 'when true' do
        let(:params) { { subscribed_only: true } }

        it 'returns only subscribed saved views' do
          expect(finder).to contain_exactly(saved_view1)
        end
      end

      context 'when false' do
        let(:params) { { subscribed_only: false } }

        it 'returns all visible saved views in namespace' do
          expect(finder).to contain_exactly(saved_view1, saved_view2)
        end
      end

      context 'when user is nil' do
        let(:params) { { subscribed_only: true } }

        subject(:finder) { described_class.new(user: nil, namespace: group, params: params).execute }

        it 'returns all public saved views in namespace' do
          expect(finder).to contain_exactly(saved_view1, saved_view2)
        end
      end
    end

    context 'with sort param' do
      context 'when sort is :id' do
        let(:params) { { sort: :id } }

        it 'returns saved views sorted by id descending' do
          expect(finder.to_a).to eq([saved_view2, saved_view1])
        end
      end

      context 'when sort is :relative_position' do
        let!(:user_saved_view1) do
          create(:user_saved_view, user: user, saved_view: saved_view1, namespace: group, relative_position: 1000)
        end

        let!(:user_saved_view2) do
          create(:user_saved_view, user: user, saved_view: saved_view2, namespace: group, relative_position: 2000)
        end

        let(:params) { { sort: :relative_position, subscribed_only: true } }

        it 'returns saved views sorted by relative position ascending' do
          expect(finder.to_a).to eq([saved_view1, saved_view2])
        end

        context 'when subscribed_only is false' do
          let(:params) { { sort: :relative_position, subscribed_only: false } }

          it 'falls back to id sort' do
            expect(finder.to_a).to eq([saved_view2, saved_view1])
          end
        end

        context 'when user is nil' do
          let(:params) { { sort: :relative_position, subscribed_only: true } }

          subject(:finder) { described_class.new(user: nil, namespace: group, params: params).execute }

          it 'falls back to id sort' do
            expect(finder.to_a).to eq([saved_view2, saved_view1])
          end
        end
      end
    end

    context 'with visibility filtering' do
      context 'when user is the author of private view' do
        let_it_be(:users_private_view) { create(:saved_view, namespace: group, author: user, private: true) }

        it 'returns user authored private views' do
          expect(finder).to contain_exactly(saved_view1, saved_view2, users_private_view)
        end
      end

      context 'when user is nil' do
        subject(:finder) { described_class.new(user: nil, namespace: group, params: params).execute }

        it 'returns only public saved views' do
          expect(finder).to contain_exactly(saved_view1, saved_view2)
        end
      end
    end
  end
end
