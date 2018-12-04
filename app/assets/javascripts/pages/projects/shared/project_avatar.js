import $ from 'jquery';

export default function projectAvatar() {
  $('.js-choose-project-avatar-button').bind('click', function onClickAvatar() {
    const form = $(this).closest('form');
    return form.find('.js-project-avatar-input').click();
  });

  $('.js-project-avatar-input').bind('change', function onClickAvatarInput() {
    const form = $(this).closest('form');
    const filename = $(this)
      .val()
      .replace(/^.*[\\\/]/, ''); // eslint-disable-line no-useless-escape
    return form.find('.js-avatar-filename').text(filename);
  });
}
