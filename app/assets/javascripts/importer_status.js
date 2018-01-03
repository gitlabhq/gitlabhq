class ImporterStatus {
  constructor(jobsUrl, importUrl) {
    this.jobsUrl = jobsUrl;
    this.importUrl = importUrl;
    this.initStatusPage();
    this.setAutoUpdate();
  }

  initStatusPage() {
    $('.js-add-to-import')
      .off('click')
      .on('click', (event) => {
        const $btn = $(event.currentTarget);
        const $tr = $btn.closest('tr');
        const $targetField = $tr.find('.import-target');
        const $namespaceInput = $targetField.find('.js-select-namespace option:selected');
        const id = $tr.attr('id').replace('repo_', '');
        let targetNamespace;
        let newName;
        if ($namespaceInput.length > 0) {
          targetNamespace = $namespaceInput[0].innerHTML;
          newName = $targetField.find('#path').prop('value');
          $targetField.empty().append(`${targetNamespace}/${newName}`);
        }
        $btn.disable().addClass('is-loading');

        return $.post(this.importUrl, {
          repo_id: id,
          target_namespace: targetNamespace,
          new_name: newName,
        }, {
          dataType: 'script',
        });
      });

    $('.js-import-all')
      .off('click')
      .on('click', function onClickImportAll() {
        const $btn = $(this);
        $btn.disable().addClass('is-loading');
        return $('.js-add-to-import').each(function triggerAddImport() {
          return $(this).trigger('click');
        });
      });
  }

  setAutoUpdate() {
    return setInterval(() => $.get(this.jobsUrl, data => $.each(data, (i, job) => {
      const jobItem = $(`#project_${job.id}`);
      const statusField = jobItem.find('.job-status');

      const spinner = '<i class="fa fa-spinner fa-spin"></i>';

      switch (job.import_status) {
        case 'finished':
          jobItem.removeClass('active').addClass('success');
          statusField.html('<span><i class="fa fa-check"></i> done</span>');
          break;
        case 'scheduled':
          statusField.html(`${spinner} scheduled`);
          break;
        case 'started':
          statusField.html(`${spinner} started`);
          break;
        default:
          statusField.html(job.import_status);
          break;
      }
    })), 4000);
  }
}

// eslint-disable-next-line consistent-return
export default function initImporterStatus() {
  const importerStatus = document.querySelector('.js-importer-status');

  if (importerStatus) {
    const data = importerStatus.dataset;
    return new ImporterStatus(data.jobsImportPath, data.importPath);
  }
}
