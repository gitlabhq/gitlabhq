class Wikis
  constructor: ->
    modal = $('#modal-new-wiki').modal({modal: true, show:false})

    $('.add-new-wiki').bind "click", ->
      modal.show()

    $('.build-new-wiki').bind "click", ->
      field = $('#new_wiki_path')
      slug = field.val()
      path = field.attr('data-wikis-path')

      if(slug.length > 0)
        location.href = path + "/" + slug

    $('.modal-header .close').bind "click", ->
      modal.hide()

@Wikis = Wikis
