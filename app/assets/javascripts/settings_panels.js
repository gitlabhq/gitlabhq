import $ from 'jquery';
import { __ } from './locale';

/**
 * Returns true if the given section is expanded or not
 *
 * For legacy consistency, it supports both jQuery and DOM elements
 *
 * @param {jQuery | Element} section
 */
export function isExpanded(sectionArg) {
  const section = sectionArg instanceof $ ? sectionArg[0] : sectionArg;

  return section.classList.contains('expanded');
}

export function expandSection(sectionArg) {
  const $section = $(sectionArg);

  $section.find('.js-settings-toggle:not(.js-settings-toggle-trigger-only)').text(__('Collapse'));
  $section.addClass('expanded');
  if (!$section.hasClass('no-animate')) {
    $section
      .addClass('animating')
      .one('animationend.animateSection', () => $section.removeClass('animating'));
  }
}

export function closeSection(sectionArg) {
  const $section = $(sectionArg);

  $section.find('.js-settings-toggle:not(.js-settings-toggle-trigger-only)').text(__('Expand'));
  $section.removeClass('expanded');
  if (!$section.hasClass('no-animate')) {
    $section
      .addClass('animating')
      .one('animationend.animateSection', () => $section.removeClass('animating'));
  }
}

export function toggleSection($section) {
  $section.removeClass('no-animate');
  if (isExpanded($section)) {
    closeSection($section);
  } else {
    expandSection($section);
  }
}

export default function initSettingsPanels() {
  $('.settings').each((i, elm) => {
    const $section = $(elm);
    $section.on('click.toggleSection', '.js-settings-toggle', () => toggleSection($section));

    if (window.location.hash) {
      const $target = $(window.location.hash);
      if (
        $target.length &&
        !isExpanded($section) &&
        ($section.is($target) || $section.find($target).length)
      ) {
        $section.addClass('no-animate');
        expandSection($section);
      }
    }
  });
}
