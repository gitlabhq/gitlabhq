# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Boards::Lists::Create do
  include GraphqlHelpers

  let_it_be(:group) { create(:group, :private) }
  let_it_be(:board) { create(:board, group: group) }
  let_it_be(:user)  { create(:user) }
  let_it_be(:guest) { create(:user) }

  let(:current_user) { user }
  let(:mutation) { described_class.new(object: nil, context: { current_user: current_user }, field: nil) }
  let(:list_create_params) { {} }

  before_all do
    group.add_reporter(user)
    group.add_guest(guest)
  end

  subject { mutation.resolve(board_id: board.to_global_id.to_s, **list_create_params) }

  describe '#ready?' do
    it 'raises an error if required arguments are missing' do
      expect { mutation.ready?(board_id: 'some id') }
        .to raise_error(Gitlab::Graphql::Errors::ArgumentError, /one and only one of/)
    end

    it 'raises an error if too many required arguments are specified' do
      expect { mutation.ready?(board_id: 'some id', backlog: true, label_id: 'some label') }
        .to raise_error(Gitlab::Graphql::Errors::ArgumentError, /one and only one of/)
    end
  end

  describe '#resolve' do
    context 'with proper permissions' do
      describe 'backlog list' do
        let(:list_create_params) { { backlog: true } }

        it 'creates one and only one backlog' do
          expect { subject }.to change { board.lists.backlog.count }.from(0).to(1)
          expect(board.lists.backlog.first.list_type).to eq 'backlog'

          backlog_id = board.lists.backlog.first.id

          expect { subject }.not_to change { board.lists.backlog.count }
          expect(board.lists.backlog.last.id).to eq backlog_id
        end
      end

      describe 'label list' do
        let_it_be(:dev_label) do
          create(:group_label, title: 'Development', color: '#FFAABB', group: group)
        end

        let(:list_create_params) { { label_id: dev_label.to_global_id.to_s } }

        it 'creates a new issue board list for labels' do
          expect { subject }.to change { board.lists.count }.from(1).to(2)

          new_list = subject[:list]

          expect(new_list.title).to eq dev_label.title
          expect(new_list.position).to eq 0
        end

        context 'when label not found' do
          let(:list_create_params) { { label_id: "gid://gitlab/Label/#{non_existing_record_id}" } }

          it 'raises an error' do
            expect { subject }
              .to raise_error(Gitlab::Graphql::Errors::ArgumentError, 'Label not found!')
          end
        end
      end
    end

    context 'without proper permissions' do
      let(:current_user) { guest }

      it 'raises an error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end
  end
end
