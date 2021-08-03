# frozen_string_literal: true

class TodoPolicy < BasePolicy
  desc 'User can only read own todos'
  condition(:own_todo) do
    @user && @subject.user_id == @user.id
  end
  condition(:can_read_target) do
    @user && @subject.target&.readable_by?(@user)
  end

  rule { own_todo & can_read_target }.enable :read_todo
  rule { own_todo & can_read_target }.enable :update_todo
end
