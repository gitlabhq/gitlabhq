import $ from 'jquery';

export default function initAvatarPicker() {
  $('.js-choose-avatar-button').on('click', function onClickAvatar() {
    const form = $(this).closest('form');
    return form.find('.js-avatar-input').click();
  });

  $('.js-avatar-input').on('change', function onChangeAvatarInput() {
    const form = $(this).closest('form');
    const filename = $(this)
      .val()
      .replace(/^.*[\\\/]/, ''); // eslint-disable-line no-useless-escape
    return form.find('.js-avatar-filename').text(filename);
  });
}
