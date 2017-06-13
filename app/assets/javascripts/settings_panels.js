function expandSection($section) {
  $section.find('.js-settings-toggle').text('Close');
  $section.find('.settings-content').addClass('expanded').off('scroll').scrollTop(0);
}

function closeSection($section) {
  $section.find('.js-settings-toggle').text('Expand');
  $section.find('.settings-content').removeClass('expanded').on('scroll', () => expandSection($section));
}

function toggleSection($section) {
  const $content = $section.find('.settings-content');
  $content.removeClass('no-animate');
  if ($content.hasClass('expanded')) {
    closeSection($section);
  } else {
    expandSection($section);
  }
}

export default function initSettingsPanels() {
  $('.settings').each((i, elm) => {
    const $section = $(elm);
    $section.on('click', '.js-settings-toggle', () => toggleSection($section));
    $section.find('.settings-content:not(.expanded)').on('scroll', () => expandSection($section));
  });
}
