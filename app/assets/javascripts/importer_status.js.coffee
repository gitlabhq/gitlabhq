class @ImporterStatus
  constructor: (@jobs_url, @import_url) ->
    this.initStatusPage()
    this.setAutoUpdate()

  initStatusPage: ->
    $('.js-add-to-import')
      .off 'click'
      .on 'click', (e) =>
        $btn = $(e.currentTarget)
        $tr = $btn.closest('tr')
        $target_field = $tr.find('.import-target')
        $namespace_input = $target_field.find('input')
        id = $tr.attr('id').replace('repo_', '')
        new_namespace = null

        if $namespace_input.length > 0
          new_namespace = $namespace_input.prop('value')
          $target_field.empty().append("#{new_namespace}/#{$target_field.data('project_name')}")

        $btn
          .disable()
          .addClass 'is-loading'

        $.post @import_url, {repo_id: id, new_namespace: new_namespace}, dataType: 'script'

    $('.js-import-all')
      .off 'click'
      .on 'click', (e) ->
        $btn = $(@)
        $btn
          .disable()
          .addClass 'is-loading'

        $('.js-add-to-import').each ->
          $(this).trigger('click')

  setAutoUpdate: ->
    setInterval (=>
      $.get @jobs_url, (data) =>
        $.each data, (i, job) =>
          job_item = $("#project_" + job.id)
          status_field = job_item.find(".job-status")

          if job.import_status == 'finished'
            job_item.removeClass("active").addClass("success")
            status_field.html('<span><i class="fa fa-check"></i> done</span>')
          else if job.import_status == 'started'
            status_field.html("<i class='fa fa-spinner fa-spin'></i> started")
          else
            status_field.html(job.import_status)

    ), 4000
