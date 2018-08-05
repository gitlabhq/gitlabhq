import $ from 'jquery';

const bindEvents = () => {
  const $newProjectForm = $('#new_project');
  const $useCustomTemplateBtn = $('.custom-template-button > input');
  const $projectFieldsForm = $('.project-fields-form');
  const $selectedIcon = $('.selected-icon');
  const $selectedTemplateText = $('.selected-template');
  const $templateProjectNameInput = $('#template-project-name #project_path');
  const $changeTemplateBtn = $('.change-template');
  const $projectTemplateButtons = $('.project-templates-buttons');
  const $projectFieldsFormInput = $('.project-fields-form input#project_use_custom_template');

  if ($newProjectForm.length !== 1 || $useCustomTemplateBtn.length === 0) {
    return;
  }

  function enableCustomTemplate() {
    $projectFieldsFormInput.val(true);
  }

  function disableCustomTemplate() {
    $projectFieldsFormInput.val(false);
  }

  function chooseTemplate() {
    $projectTemplateButtons.addClass('hidden');
    $projectFieldsForm.addClass('selected');
    $selectedIcon.empty();

    const value = $(this).val();

    $selectedTemplateText.text(value);
    $(this)
      .parents('.template-option')
      .find('.avatar')
      .clone()
      .addClass('d-block')
      .removeClass('s40')
      .appendTo($selectedIcon);

    $templateProjectNameInput.focus();
    enableCustomTemplate();
  }

  $useCustomTemplateBtn.on('change', chooseTemplate);

  $changeTemplateBtn.on('click', () => {
    $projectTemplateButtons.removeClass('hidden');
    $useCustomTemplateBtn.prop('checked', false);
    disableCustomTemplate();
  });
};

export default () => {

  const $navElement = $('.nav-link[href="#custom-templates"]');
  const $tabContent = $('.project-templates-buttons#custom-templates');

  $tabContent.on('ajax:success', bindEvents);

  $navElement.one('click', () => {
    $.get($tabContent.data('initialTemplates'));
  });

  bindEvents();
};
