import $ from 'jquery';

function expandSection($section) {
  $section.find('.js-settings-toggle').text('Collapse');
  $section.find('.settings-content').off('scroll.expandSection').scrollTop(0);
  $section.addClass('expanded');
  if (!$section.hasClass('no-animate')) {
    $section.addClass('animating')
      .one('animationend.animateSection', () => $section.removeClass('animating'));
  }
}

function closeSection($section) {
  $section.find('.js-settings-toggle').text('Expand');
  $section.find('.settings-content').on('scroll.expandSection', () => expandSection($section));
  $section.removeClass('expanded');
  if (!$section.hasClass('no-animate')) {
    $section.addClass('animating')
      .one('animationend.animateSection', () => $section.removeClass('animating'));
  }
}

function toggleSection($section) {
  $section.removeClass('no-animate');
  if ($section.hasClass('expanded')) {
    closeSection($section);
  } else {
    expandSection($section);
  }
}

export default function initSettingsPanels() {
  $('.settings').each((i, elm) => {
    const $section = $(elm);
    $section.on('click.toggleSection', '.js-settings-toggle', () => toggleSection($section));

    if (!$section.hasClass('expanded')) {
      $section.find('.settings-content').on('scroll.expandSection', () => {
        $section.removeClass('no-animate');
        expandSection($section);
      });
    }
  });

  if (location.hash) {
    const $target = $(location.hash);
    if ($target.length && $target.hasClass('settings')) {
      expandSection($target);
    }
  }
}
