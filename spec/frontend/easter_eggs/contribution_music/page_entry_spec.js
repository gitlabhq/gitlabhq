import AjaxCache from '~/lib/utils/ajax_cache';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import waitForPromises from 'helpers/wait_for_promises';

jest.mock('~/lib/utils/ajax_cache');
jest.mock('~/users/profile/actions', () => ({ initUserActionsApp: () => {} }));
jest.mock('~/profile', () => ({ initUserAchievements: () => {} }));
jest.mock('~/user_callout', () => jest.fn());
// The player itself needs canvas and Web Audio, so it's covered by its own spec.
jest.mock('~/easter_eggs/contribution_music/components/contribution_music_app.vue', () => ({
  render: (createElement) => createElement('div', { attrs: { id: 'contribution-music' } }),
}));

// The real profile page entry, so the ordering against the Vue activity
// calendar mount is exercised the way the browser runs it.
describe('pages/users entry with ?play', () => {
  afterEach(() => resetHTMLFixture());

  it('opens the modal with the Vue activity calendar enabled', async () => {
    AjaxCache.retrieve.mockResolvedValue({ '2026-09-01': 5 });
    window.gon = {
      dot_com: true,
      first_day_of_week: 0,
      features: { contributionMusicEasterEgg: true },
    };
    delete window.location;
    window.location = new URL('https://gdk.test/root?play');

    setHTMLFixture(`
      <div class="user-profile">
        <div id="js-legacy-tabs-container" data-action="overview" data-endpoint="/root">
          <div id="js-vue-activity-calendar" data-username="root" data-utc-offset="0"></div>
        </div>
      </div>
    `);
    document.body.dataset.page = 'users:show';

    await import('~/pages/users/index');
    await waitForPromises();

    expect(document.getElementById('contribution-music')).not.toBe(null);
    expect(document.getElementById('js-vue-activity-calendar')).toBe(null);
  });
});
