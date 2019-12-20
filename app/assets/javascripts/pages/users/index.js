import $ from 'jquery';
import Cookies from 'js-cookie';
import UserCallout from '~/user_callout';
import UserTabs from './user_tabs';

function initUserProfile(action) {
  // place profile avatars to top
  $('.profile-groups-avatars').tooltip({
    placement: 'top',
  });

  // eslint-disable-next-line no-new
  new UserTabs({ parentEl: '.user-profile', action });

  // hide project limit message
  $('.hide-project-limit-message').on('click', e => {
    e.preventDefault();
    Cookies.set('hide_project_limit_message', 'false');
    $(this)
      .parents('.project-limit-message')
      .remove();
  });
}

document.addEventListener('DOMContentLoaded', () => {
  const page = $('body').attr('data-page');
  const action = page.split(':')[1];
  initUserProfile(action);
  new UserCallout(); // eslint-disable-line no-new
});
