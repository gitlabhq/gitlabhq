module EE
  module TodosHelper
    extend ::Gitlab::Utils::Override

    override :todo_types_options
    def todo_types_options
      super << { id: 'Epic', text: 'Epic' }
    end
  end
end
