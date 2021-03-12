import $ from 'jquery';
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

  $('body').on('click', '.js-toggle-button', function toggleButton(e) {
    e.currentTarget.classList.toggle(e.currentTarget.dataset.toggleOpenClass || 'selected');
    toggleContainer($(this).closest('.js-toggle-container'));

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
});
