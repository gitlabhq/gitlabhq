import $ from 'jquery';
import { fixTitle } from '~/tooltips';
import { getLocationHash } from '../lib/utils/url_utility';

// Toggle button. Show/hide content inside parent container.
// Button does not change visibility. If button has icon - it changes chevron style.
//
// %div.js-toggle-container
//   %button.js-toggle-button
//   %div.js-toggle-content
//

$(() => {
  function toggleContainer(container, toggleState) {
    const $container = $(container);
    const isExpanded = $container.data('is-expanded');
    const $collapseIcon = $container.find('.js-sidebar-collapse');
    const $expandIcon = $container.find('.js-sidebar-expand');

    if (isExpanded && !toggleState) {
      $container.data('is-expanded', false);
      $collapseIcon.addClass('hidden');
      $expandIcon.removeClass('hidden');
    } else {
      $container.data('is-expanded', true);
      $expandIcon.addClass('hidden');
      $collapseIcon.removeClass('hidden');
    }

    $container.find('.js-toggle-content').toggle(toggleState);
  }

  function updateTitle(el, container) {
    const $container = $(container);
    const isExpanded = $container.data('is-expanded');

    el.setAttribute('title', isExpanded ? el.dataset.collapseTitle : el.dataset.expandTitle);

    fixTitle(el);
  }

  $('body').on('click', '.js-toggle-button', function toggleButton(e) {
    e.currentTarget.classList.toggle(e.currentTarget.dataset.toggleOpenClass || 'selected');

    const containerEl = this.closest('.js-toggle-container');

    toggleContainer(containerEl);
    updateTitle(this, containerEl);

    const targetTag = e.currentTarget.tagName.toLowerCase();
    if (targetTag === 'a' || targetTag === 'button') {
      e.preventDefault();
    }
  });

  // If we're accessing a permalink, ensure it is not inside a
  // closed js-toggle-container!
  const hash = getLocationHash();
  const anchor = hash && document.getElementById(hash);
  const container = anchor && $(anchor).closest('.js-toggle-container');

  if (container) {
    toggleContainer(container, true);
    anchor.scrollIntoView();
  }

  function crudToggleSection(section, toggleState) {
    const collapseIcon = section.querySelector('.js-crud-collapsible-collapse');
    const expandIcon = section.querySelector('.js-crud-collapsible-expand');
    const crudBody = section.querySelector('.crud-body');
    const crudHeader = section.querySelector('.crud-header');
    const crudFooter = section.querySelector('[data-testid="crud-footer"]');
    const crudForm = section.querySelector('[data-testid="crud-form"]');
    const toggleButton = section.querySelector('.js-crud-collapsible-button');
    const isExpanded = toggleButton.ariaExpanded === 'true';

    if (isExpanded && !toggleState) {
      toggleButton.ariaExpanded = 'false';
      collapseIcon?.classList.add('gl-hidden');
      expandIcon?.classList.remove('gl-hidden');
      crudBody?.classList.add('!gl-hidden');
      crudFooter?.classList.add('!gl-hidden');
      crudForm?.classList.add('!gl-hidden');
      crudHeader?.classList.add('gl-rounded-base', 'gl-border-b-transparent');
    } else {
      toggleButton.ariaExpanded = 'true';
      expandIcon?.classList.add('gl-hidden');
      collapseIcon?.classList.remove('gl-hidden');
      crudBody?.classList.remove('!gl-hidden');
      crudFooter?.classList.remove('!gl-hidden');
      crudForm?.classList.remove('!gl-hidden');
      crudHeader?.classList.remove('gl-rounded-base', 'gl-border-b-transparent');
    }

    toggleButton.setAttribute(
      'title',
      isExpanded ? toggleButton.dataset.collapseTitle : toggleButton.dataset.expandTitle,
    );
    fixTitle(toggleButton);
  }

  // Crud section collapsible.
  document.body.addEventListener('click', (e) => {
    if (e.target.closest('.js-crud-collapsible-button')) {
      const button = e.target.closest('.js-crud-collapsible-button');
      const containerEl = button.closest('.js-crud-collapsible-section');

      crudToggleSection(containerEl);

      const targetTag = e.target.tagName.toLowerCase();
      if (targetTag === 'a' || targetTag === 'button') {
        e.preventDefault();
      }
    }
  });
});
