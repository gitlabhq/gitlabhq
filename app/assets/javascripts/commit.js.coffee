class Commit
  constructor: ->
    $('.files .file').each ->
      new CommitFile(this)

@Commit = Commit
