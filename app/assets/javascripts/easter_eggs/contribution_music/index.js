import Vue from 'vue';
import { noop } from 'lodash-es';
import { getParameterValues } from '~/lib/utils/url_utility';
import { userCalendarPath } from '~/lib/utils/path_helpers/user';
import { listenForTrigger } from './trigger';
import { initInPlacePlayer } from './in_place';

const PARAM = 'play';

let app = null;
let isLoading = false;

const mountPlayer = async (props) => {
  if (app || isLoading) {
    return;
  }

  isLoading = true;

  let ContributionMusicApp;

  try {
    ({ default: ContributionMusicApp } = await import(
      /* webpackChunkName: 'contributionMusicApp' */ './components/contribution_music_app.vue'
    ));
  } finally {
    isLoading = false;
  }

  const el = document.createElement('div');
  document.body.appendChild(el);

  app = new Vue({
    el,
    name: 'ContributionMusicRoot',
    render(createElement) {
      return createElement(ContributionMusicApp, {
        props,
        on: {
          hidden: () => {
            this.$destroy();
            this.$el.remove();
            app = null;
          },
        },
      });
    },
  });
};

export const initContributionMusic = () => {
  // GitLab.com only: the video and share copy speak for GitLab, which self-managed instances don't.
  if (!gon.dot_com || !gon.features?.contributionMusicEasterEgg) {
    return;
  }

  const calendar =
    document.getElementById('js-vue-activity-calendar') ?? document.querySelector('.user-calendar');

  if (!calendar) {
    return;
  }

  const { username, calendarPath } = calendar.dataset;
  const path = calendarPath ?? (username && userCalendarPath({ username, format: 'json' }));

  if (!path) {
    return;
  }

  const profileUsername = username ?? calendarPath.match(/\/users\/([^/]+)\/calendar/)?.[1];

  if (!profileUsername) {
    return;
  }

  const utcOffset = Number(calendar.dataset.utcOffset ?? 0);
  const firstDayOfWeek = gon.first_day_of_week ?? 0;
  const props = {
    calendarPath: path,
    utcOffset,
    firstDayOfWeek,
    username: profileUsername,
    name:
      document.querySelector('.user-profile-header [itemprop="name"]')?.textContent.trim() || null,
    currentUsername: gon.current_username ?? null,
    avatarUrl: document.querySelector('.user-profile-header .user-image a')?.href ?? null,
  };

  let stopInPlace = noop;
  const openPlayer = ({ hasPlayed = false } = {}) => {
    stopInPlace();
    mountPlayer({ ...props, hasPlayed });
  };

  // Only the legacy calendar for now, since the Vue one isn't in production yet.
  if (calendar.classList.contains('user-calendar')) {
    stopInPlace = initInPlacePlayer({
      calendar,
      firstDayOfWeek,
      onOpen: () => openPlayer({ hasPlayed: true }),
    });
  }

  listenForTrigger({
    calendarPath: path,
    utcOffset,
    firstDayOfWeek,
    onTrigger: () => openPlayer(),
  });

  if (getParameterValues(PARAM).length) {
    openPlayer();
  }
};
