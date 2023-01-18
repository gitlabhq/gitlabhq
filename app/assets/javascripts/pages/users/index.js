import $ from 'jquery';
import { setCookie } from '~/lib/utils/common_utils';
import UserCallout from '~/user_callout';
import { initReportAbuse } from '~/users/profile';
import UserTabs from './user_tabs';

function initUserProfile(action) {
  // eslint-disable-next-line no-new
  new UserTabs({ parentEl: '.user-profile', action });

  // hide project limit message
  $('.hide-project-limit-message').on('click', (e) => {
    e.preventDefault();
    setCookie('hide_project_limit_message', 'false');
    $(this).parents('.project-limit-message').remove();
  });
}

const page = $('body').attr('data-page');
const action = page.split(':')[1];
initUserProfile(action);
new UserCallout(); // eslint-disable-line no-new
initReportAbuse();
