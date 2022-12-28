# frozen_string_literal: true

class TodoPolicy < BasePolicy
  desc 'User can only read own todos'
  condition(:own_todo) do
    @user && @subject.user_id == @user.id
  end

  desc "User can read the todo's target"
  condition(:can_read_target) do
    @user && @subject.target&.readable_by?(@user)
  end

  desc "Todo has internal note"
  condition(:has_internal_note, scope: :subject) { @subject&.note&.confidential? }

  desc "User can read the todo's internal note"
  condition(:can_read_todo_internal_note) do
    @user && @user.can?(:read_internal_note, @subject.target)
  end

  rule { own_todo & can_read_target }.enable :read_todo
  rule { can?(:read_todo) }.enable :update_todo

  rule { has_internal_note & ~can_read_todo_internal_note }.policy do
    prevent :read_todo
    prevent :update_todo
  end
end
