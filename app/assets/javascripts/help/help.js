// We will render the icons list here

import $ from 'jquery';

export default () => {
  if ($('#user-content-gitlab-icons').length > 0) {
    const $iconsHeader = $('#user-content-gitlab-icons');
    const $iconsList = $('<div id="iconsList">ICONS</div>');
    $($iconsList).insertAfter($iconsHeader.parent());
  }
};
