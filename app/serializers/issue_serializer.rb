class IssueSerializer < BaseSerializer
  # This overrided method takes care of which entity should be used
  # to serialize the `issue` based on `basic` key in `opts` param.
  # Hence, `entity` doesn't need to be declared on the class scope.
  def represent(merge_request, opts = {})
    entity =
      case opts[:serializer]
      when 'sidebar'
        IssueSidebarEntity
      else
        IssueEntity
      end

    super(merge_request, opts, entity)
  end
end
