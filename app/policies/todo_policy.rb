# frozen_string_literal: true

class TodoPolicy < BasePolicy
  desc 'User can only read own todos'
  condition(:own_todo) do
    @user && @subject.user_id == @user.id
  end

  rule { own_todo }.enable :read_todo
  rule { own_todo }.enable :update_todo
end
