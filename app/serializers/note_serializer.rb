class NoteSerializer < BaseSerializer
  # This overrided method takes care of which entity should be used
  # to serialize the `note` based on `basic` key in `opts` param.
  # Hence, `entity` doesn't need to be declared on the class scope.
  def represent(note, opts = {})
    entity = opts[:basic] ? NoteBasicEntity : API::Entities::Note
    super(note, opts, entity)
  end
end
