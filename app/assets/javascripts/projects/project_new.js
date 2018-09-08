import $ from 'jquery';
import { addSelectOnFocusBehaviour } from '../lib/utils/common_utils';
import { slugifyWithHyphens } from '../lib/utils/text_utility';

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

const onProjectNameChange = ($projectNameInput, $projectPathInput) => {
  const slug = slugifyWithHyphens($projectNameInput.val());
  $projectPathInput.val(slug);
};

const bindEvents = () => {
  const $newProjectForm = $('#new_project');
  const $projectImportUrl = $('#project_import_url');
  const $projectPath = $('.tab-pane.active #project_path');
  const $useTemplateBtn = $('.template-button > input');
  const $projectFieldsForm = $('.project-fields-form');
  const $selectedTemplateText = $('.selected-template');
  const $changeTemplateBtn = $('.change-template');
  const $selectedIcon = $('.selected-icon');
  const $pushNewProjectTipTrigger = $('.push-new-project-tip');
  const $projectTemplateButtons = $('.project-templates-buttons');
  const $projectName = $('.tab-pane.active #project_name');

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
    $('.btn_import_gitlab_project')
      .attr('href', `${importHref}?namespace_id=${$('#project_namespace_id').val()}&name=${$projectName.val()}&path=${$projectPath.val()}`);
  });

  if ($pushNewProjectTipTrigger) {
    $pushNewProjectTipTrigger
      .removeAttr('rel')
      .removeAttr('target')
      .on('click', (e) => { e.preventDefault(); })
      .popover({
        title: $pushNewProjectTipTrigger.data('title'),
        placement: 'bottom',
        html: true,
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
    $projectTemplateButtons.addClass('hidden');
    $projectFieldsForm.addClass('selected');
    $selectedIcon.empty();
    const value = $(this).val();
    const templates = {
      rails: {
        text: 'Ruby on Rails',
        icon: '.template-option svg.icon-rails',
      },
      express: {
        text: 'NodeJS Express',
        icon: '.template-option svg.icon-node-express',
      },
      spring: {
        text: 'Spring',
        icon: '.template-option svg.icon-java-spring',
      },
    };

    const selectedTemplate = templates[value];
    $selectedTemplateText.text(selectedTemplate.text);
    $(selectedTemplate.icon).clone().addClass('d-block').appendTo($selectedIcon);

    const $activeTabProjectName = $('.tab-pane.active #project_name');
    const $activeTabProjectPath = $('.tab-pane.active #project_path');
    $activeTabProjectName.focus();
    $activeTabProjectName
      .keyup(() => {
        onProjectNameChange($activeTabProjectName, $activeTabProjectPath);
        hasUserDefinedProjectPath = $activeTabProjectPath.val().trim().length > 0;
      });
  }

  $useTemplateBtn.on('change', chooseTemplate);

  $changeTemplateBtn.on('click', () => {
    $projectTemplateButtons.removeClass('hidden');
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

<<<<<<< HEAD
  $('.js-import-git-toggle-button').on('click', () => {
    const $projectMirror = $('#project_mirror');

    $projectMirror.attr('disabled', !$projectMirror.attr('disabled'));
  });

=======
>>>>>>> upstream/master
  $projectName.keyup(() => {
    onProjectNameChange($projectName, $projectPath);
    hasUserDefinedProjectPath = $projectPath.val().trim().length > 0;
  });
};

export default {
  bindEvents,
  deriveProjectPathFromUrl,
  onProjectNameChange,
};
