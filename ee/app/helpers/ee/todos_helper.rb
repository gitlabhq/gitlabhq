module EE
  module TodosHelper
    extend ::Gitlab::Utils::Override

    override :todo_types_options
    def todo_types_options
      super << { id: 'Epic', text: 'Epic' }
    end

    def todo_group_options
      groups = current_user.authorized_groups

      groups = groups.map do |group|
        { id: group.id, text: group.full_name }
      end

      groups.unshift({ id: '', text: 'Any Group' }).to_json
    end
  end
end
