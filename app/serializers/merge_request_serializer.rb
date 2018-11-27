# frozen_string_literal: true

class MergeRequestSerializer < BaseSerializer
  # This overrided method takes care of which entity should be used
  # to serialize the `merge_request` based on `serializer` key in `opts` param.
  # Hence, `entity` doesn't need to be declared on the class scope.
  def represent(merge_request, opts = {})
    entity =
      case opts[:serializer]
      when 'sidebar_extras'
        opts[:include_basic] = false
        opts[:include_extras] = true
        MergeRequestSidebarEntity
      when 'basic'
        MergeRequestBasicEntity
      else
        # fallback to widget for old poll requests without `serializer` set
        MergeRequestWidgetEntity
      end

    super(merge_request, opts, entity)
  end
end
