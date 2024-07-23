# frozen_string_literal: true

class MergeRequestSerializer < BaseSerializer
  # This overrided method takes care of which entity should be used
  # to serialize the `merge_request` based on `serializer` key in `opts` param.
  # Hence, `entity` doesn't need to be declared on the class scope.
  def represent(merge_request, opts = {}, entity = nil)
    entity ||= identified_entity(opts)

    super(merge_request, opts, entity)
  end

  def identified_entity(opts)
    case opts[:serializer]
    when 'sidebar'
      MergeRequestSidebarBasicEntity
    when 'sidebar_extras'
      MergeRequestSidebarExtrasEntity
    when 'basic'
      MergeRequestBasicEntity
    when 'noteable'
      MergeRequestNoteableEntity
    when 'poll_cached_widget'
      MergeRequestPollCachedWidgetEntity
    when 'poll_widget'
      MergeRequestPollWidgetEntity
    else
      # fallback to widget for old poll requests without `serializer` set
      MergeRequestWidgetEntity
    end
  end
end

MergeRequestSerializer.prepend_mod
