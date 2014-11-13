class @CommitFile

  constructor: (file) ->
    if $('.image', file).length
      new ImageFile(file)
