import $ from 'jquery';
import { parseBoolean } from '~/lib/utils/common_utils';
import { InternalEvents } from '~/tracking';
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
  const title = $section.find('.js-settings-toggle-trigger-only').text();

  $section
    .find('.js-settings-toggle:not(.js-settings-toggle-trigger-only) .gl-button-text')
    .text(__('Collapse'));
  $section
    .find('.js-settings-toggle:not(.js-settings-toggle-trigger-only)')
    .attr('aria-label', `${__('Collapse')} ${title}`);
  $section.addClass('expanded');
  if (!$section.hasClass('no-animate')) {
    $section
      .addClass('animating')
      .one('animationend.animateSection', () => $section.removeClass('animating'));
  }

  InternalEvents.trackEvent('click_expand_panel_on_settings', {
    label: $section.find('[data-event-tracking="settings-block-title"]').text(),
  });
}

export function closeSection(sectionArg) {
  const $section = $(sectionArg);
  const title = $section.find('.js-settings-toggle-trigger-only').text();

  $section
    .find('.js-settings-toggle:not(.js-settings-toggle-trigger-only) .gl-button-text')
    .text(__('Expand'));
  $section
    .find('.js-settings-toggle:not(.js-settings-toggle-trigger-only)')
    .attr('aria-label', `${__('Expand')} ${title}`);

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

    // If ID set, remove URL
    if ($section.attr('id')) {
      // eslint-disable-next-line no-restricted-globals
      history.pushState('', document.title, window.location.pathname + window.location.search);
    }
  } else {
    expandSection($section);

    // If ID set, add to URL
    if ($section.attr('id')) {
      // eslint-disable-next-line no-restricted-globals
      location.hash = $section.attr('id');
    }
  }
}

export function initTrackProductAnalyticsExpanded() {
  const $analyticsSection = $('#js-product-analytics-settings');
  $analyticsSection.on('click.toggleSection', '.js-settings-toggle', () => {
    if (isExpanded($analyticsSection)) {
      InternalEvents.trackEvent('user_viewed_cluster_configuration');
    }
  });
}

function initGlobalProtectionOptions() {
  const globalProtectionProtectedOption = document.querySelectorAll('.js-global-protection-levels');
  const protectionSettingsSection = document.querySelector(
    '.js-global-protection-levels-protected',
  );

  globalProtectionProtectedOption.forEach((option) => {
    const isProtected = parseBoolean(option.value);
    option.addEventListener('change', () => {
      protectionSettingsSection.classList.toggle('gl-hidden', !isProtected);
    });

    if (option.checked) {
      protectionSettingsSection.classList.toggle('gl-hidden', !isProtected);
    }
  });
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

  initTrackProductAnalyticsExpanded();
  initGlobalProtectionOptions();
}
