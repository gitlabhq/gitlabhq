#= require latinise

class @Wikis
  constructor: ->
    $('.build-new-wiki').bind 'click', (e) =>
      $('[data-error~=slug]').addClass('hidden')
      field = $('#new_wiki_path')
      slug = @slugify(field.val())

      if (slug.length > 0)
        path = field.attr('data-wikis-path')
        location.href = path + '/' + slug

  dasherize: (value) ->
    value.replace(/[_\s]+/g, '-')

  slugify: (value) =>
    @dasherize(value.trim().toLowerCase().latinise())
