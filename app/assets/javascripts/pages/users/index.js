import $ from 'jquery';
import { setCookie } from '~/lib/utils/common_utils';
import UserCallout from '~/user_callout';
import { initUserAchievements } from '~/profile';
import { initUserActionsApp } from '~/users/profile/actions';
import { initContributionMusic } from '~/easter_eggs/contribution_music';
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
// Before initUserProfile: mounting the Vue activity calendar replaces the
// element this reads the profile's username from.
initContributionMusic();
initUserProfile(action);
initUserAchievements();
initUserActionsApp();
new UserCallout(); // eslint-disable-line no-new
