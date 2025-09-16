# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::GroupsFilter, feature_category: :groups_and_projects do
  let(:finder_class) do
    Class.new do
      include Namespaces::GroupsFilter

      def initialize(current_user = nil, params = {})
        @current_user = current_user
        @params = params
      end

      def execute
        sort(by_search(Group.all))
      end

      private

      attr_reader :current_user, :params
    end
  end

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, owners: user, name: "group foo") }
  let_it_be(:group_2) { create(:group, owners: user, name: "group 2 foo") }
  let_it_be(:group_3) { create(:group, owners: user, name: "group 3 foo") }

  let(:params) { {} }
  let(:current_user) { user }

  subject(:finder) { finder_class.new(current_user, params).execute }

  describe '#sort' do
    context 'when sorting by similarity' do
      context 'when allow_similarity_sort is not defined' do
        let(:params) { { sort: :similarity } }

        it 'falls back to id_desc' do
          expect(finder).to eq([group_3, group_2, group])
        end
      end

      context 'when allow_similarity_sort is true' do
        context 'when search is defined' do
          let(:params) { { sort: :similarity, search: 'group 3 foo', allow_similarity_sort: true } }

          it 'sorts by similarity' do
            expect(finder).to eq([group_3, group, group_2])
          end
        end

        context 'when current_user is not defined' do
          let(:current_user) { nil }
          let(:params) { { sort: :similarity, search: 'group 3 foo', allow_similarity_sort: true } }

          it 'falls back to id_desc' do
            expect(finder).to eq([group_3, group_2, group])
          end
        end
      end
    end
  end
end
