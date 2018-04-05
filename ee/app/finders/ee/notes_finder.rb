module EE
  module NotesFinder
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    override :noteables_for_type
    def noteables_for_type(noteable_type)
      if noteable_type == "epic"
        return EpicsFinder.new(@current_user, group_id: @params[:group_id]) # rubocop:disable Gitlab/ModuleWithInstanceVariables
      end

      super
    end
  end
end
