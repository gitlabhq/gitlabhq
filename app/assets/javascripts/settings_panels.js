function expandSectionParent($section, $content) {
  $section.addClass('expanded');
  $content.off('animationend.expandSectionParent');
}

function expandSection($section) {
  $section.find('.js-settings-toggle').text('Collapse');

  const $content = $section.find('.settings-content');
  $content.addClass('expanded').off('scroll.expandSection').scrollTop(0);

  if ($content.hasClass('no-animate')) {
    expandSectionParent($section, $content);
  } else {
    $content.on('animationend.expandSectionParent', () => expandSectionParent($section, $content));
  }
}

function closeSection($section) {
  $section.find('.js-settings-toggle').text('Expand');

  const $content = $section.find('.settings-content');
  $content.removeClass('expanded').on('scroll.expandSection', () => expandSection($section));

  $section.removeClass('expanded');
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
    $section.on('click.toggleSection', '.js-settings-toggle', () => toggleSection($section));
    $section.find('.settings-content:not(.expanded)').on('scroll.expandSection', () => expandSection($section));
  });
}
