import $ from 'jquery';
import { addSelectOnFocusBehaviour } from '../lib/utils/common_utils';

let hasUserDefinedProjectPath = false;

const deriveProjectPathFromUrl = ($projectImportUrl) => {
  const $currentProjectPath = $projectImportUrl.parents('.toggle-import-form').find('#project_path');
  if (hasUserDefinedProjectPath) {
    return;
  }

  let importUrl = $projectImportUrl.val().trim();
  if (importUrl.length === 0) {
    return;
  }

  /*
    \/?: remove trailing slash
    (\.git\/?)?: remove trailing .git (with optional trailing slash)
    (\?.*)?: remove query string
    (#.*)?: remove fragment identifier
  */
  importUrl = importUrl.replace(/\/?(\.git\/?)?(\?.*)?(#.*)?$/, '');

  // extract everything after the last slash
  const pathMatch = /\/([^/]+)$/.exec(importUrl);
  if (pathMatch) {
    $currentProjectPath.val(pathMatch[1]);
  }
};

const bindEvents = () => {
  const $newProjectForm = $('#new_project');
  const $projectImportUrl = $('#project_import_url');
  const $projectPath = $('#project_path');
  const $useTemplateBtn = $('.template-button > input');
  const $projectFieldsForm = $('.project-fields-form');
  const $selectedTemplateText = $('.selected-template');
  const $changeTemplateBtn = $('.change-template');
  const $selectedIcon = $('.selected-icon svg');
  const $templateProjectNameInput = $('#template-project-name #project_path');
  const $pushNewProjectTipTrigger = $('.push-new-project-tip');

  if ($newProjectForm.length !== 1) {
    return;
  }

  $('.how_to_import_link').on('click', (e) => {
    e.preventDefault();
    $(e.currentTarget).next('.modal').show();
  });

  $('.modal-header .close').on('click', () => {
    $('.modal').hide();
  });

  $('.btn_import_gitlab_project').on('click', () => {
    const importHref = $('a.btn_import_gitlab_project').attr('href');
    $('.btn_import_gitlab_project').attr('href', `${importHref}?namespace_id=${$('#project_namespace_id').val()}&path=${$projectPath.val()}`);
  });

  if ($pushNewProjectTipTrigger) {
    $pushNewProjectTipTrigger
      .removeAttr('rel')
      .removeAttr('target')
      .on('click', (e) => { e.preventDefault(); })
      .popover({
        title: $pushNewProjectTipTrigger.data('title'),
        placement: 'auto bottom',
        html: 'true',
        content: $('.push-new-project-tip-template').html(),
      })
      .on('shown.bs.popover', () => {
        $(document).on('click.popover touchstart.popover', (event) => {
          if ($(event.target).closest('.popover').length === 0) {
            $pushNewProjectTipTrigger.trigger('click');
          }
        });

        const target = $(`#${$pushNewProjectTipTrigger.attr('aria-describedby')}`).find('.js-select-on-focus');
        addSelectOnFocusBehaviour(target);

        target.focus();
      })
      .on('hide.bs.popover', () => {
        $(document).off('click.popover touchstart.popover');
      });
  }

  function chooseTemplate() {
    $('.template-option').hide();
    $projectFieldsForm.addClass('selected');
    $selectedIcon.removeClass('active');
    const value = $(this).val();
    const templates = {
      rails: {
        text: 'Ruby on Rails',
        icon: '.selected-icon .icon-rails',
      },
      express: {
        text: 'NodeJS Express',
        icon: '.selected-icon .icon-node-express',
      },
      spring: {
        text: 'Spring',
        icon: '.selected-icon .icon-java-spring',
      },
    };

    const selectedTemplate = templates[value];
    $selectedTemplateText.text(selectedTemplate.text);
    $(selectedTemplate.icon).addClass('active');
    $templateProjectNameInput.focus();
  }

  $useTemplateBtn.on('change', chooseTemplate);

  $changeTemplateBtn.on('click', () => {
    $('.template-option').show();
    $projectFieldsForm.removeClass('selected');
    $useTemplateBtn.prop('checked', false);
  });

  $newProjectForm.on('submit', () => {
    $projectPath.val($projectPath.val().trim());
  });

  $projectPath.on('keyup', () => {
    hasUserDefinedProjectPath = $projectPath.val().trim().length > 0;
  });

  $projectImportUrl.keyup(() => deriveProjectPathFromUrl($projectImportUrl));

  $('.js-import-git-toggle-button').on('click', () => {
    const $projectMirror = $('#project_mirror');

    $projectMirror.attr('disabled', !$projectMirror.attr('disabled'));
  });
};

export default {
  bindEvents,
  deriveProjectPathFromUrl,
};
