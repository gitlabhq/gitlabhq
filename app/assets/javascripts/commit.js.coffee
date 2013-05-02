@Commit =
  init: ->
    $('.files .file').each ->
      new CommitFile(this)

