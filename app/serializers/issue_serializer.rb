# frozen_string_literal: true

class IssueSerializer < BaseSerializer
  # This overrided method takes care of which entity should be used
  # to serialize the `issue` based on `serializer` key in `opts` param.
  # Hence, `entity` doesn't need to be declared on the class scope.
  def represent(issue, opts = {})
    entity = choose_entity(opts)

    super(issue, opts, entity)
  end

  def choose_entity(opts)
    case opts[:serializer]
    when 'sidebar'
      IssueSidebarBasicEntity
    when 'sidebar_extras'
      IssueSidebarExtrasEntity
    when 'board'
      IssueBoardEntity
    else
      IssueEntity
    end
  end
end

IssueSerializer.prepend_mod_with('IssueSerializer')
