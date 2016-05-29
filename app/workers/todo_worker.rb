class TodoWorker
  include Sidekiq::Worker

  sidekiq_options queue: :default

  def perform(todo_id)
    Gitlab::Redis.with do |redis|
      todo = Todo.find(todo_id)
      data = {
        count: todo.user.todos.pending.count
      }
      redis.publish("todos.#{todo.user_id}", {count: todo.user.todos.pending.count}.to_json)
    end
  end
end
