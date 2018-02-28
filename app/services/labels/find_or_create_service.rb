module Labels
  class FindOrCreateService
    def initialize(current_user, parent, params = {})
      @current_user = current_user
      @parent = parent
      @available_labels = params.delete(:available_labels)
      @params = params.dup.with_indifferent_access
    end

    def execute(skip_authorization: false)
      @skip_authorization = skip_authorization
      find_or_create_label
    end

    private

    attr_reader :current_user, :parent, :params, :skip_authorization

    def available_labels
      @available_labels ||= LabelsFinder.new(
        current_user,
        "#{parent_type}_id".to_sym => parent.id,
        only_group_labels: parent_is_group?
      ).execute(skip_authorization: skip_authorization)
    end

    # Only creates the label if current_user can do so, if the label does not exist
    # and the user can not create the label, nil is returned
    def find_or_create_label
      new_label = available_labels.find_by(title: title)

      if new_label.nil? && (skip_authorization || Ability.allowed?(current_user, :admin_label, parent))
        new_label = Labels::CreateService.new(params).execute(parent_type.to_sym => parent)
      end

      new_label
    end

    def title
      params[:title] || params[:name]
    end

    def parent_type
      parent.model_name.param_key
    end

    def parent_is_group?
      parent_type == "group"
    end
  end
end
