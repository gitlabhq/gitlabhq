module Functions
  class Echo < BaseFunction
    argument :text, GraphQL::STRING_TYPE

    description "Testing endpoint to validate the API with"

    def call(obj, args, ctx)
      username = ctx[:current_user]&.username

      "#{username.inspect} says: #{args[:text]}"
    end
  end
end
