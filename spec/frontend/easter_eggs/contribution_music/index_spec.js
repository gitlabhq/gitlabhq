import AjaxCache from '~/lib/utils/ajax_cache';
import { initVueActivityCalendar } from '~/pages/users/vue_activity_calendar';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import waitForPromises from 'helpers/wait_for_promises';

jest.mock('~/lib/utils/ajax_cache');

const mockRender = jest.fn();

// The player itself needs canvas and Web Audio, so it's covered by its own spec.
jest.mock('~/easter_eggs/contribution_music/components/contribution_music_app.vue', () => ({
  props: ['calendarPath', 'utcOffset', 'firstDayOfWeek', 'username'],
  render(createElement) {
    mockRender(this.$props);
    return createElement('div', { attrs: { id: 'contribution-music' } });
  },
}));

const VUE_CALENDAR =
  '<div id="js-vue-activity-calendar" data-username="root" data-utc-offset="0"></div>';
const LEGACY_CALENDAR =
  '<div class="user-calendar" data-calendar-path="/users/root/calendar.json" data-utc-offset="0"></div>';

describe('initContributionMusic', () => {
  const setUrl = (url) => {
    delete window.location;
    window.location = new URL(url);
  };

  const findModal = () => document.getElementById('contribution-music');

  // The mounted player is module state, so each test gets a fresh module.
  const initContributionMusic = async () => {
    const { initContributionMusic: init } = await import('~/easter_eggs/contribution_music');
    init();
    await waitForPromises();
  };

  beforeEach(() => {
    jest.resetModules();
    mockRender.mockClear();
    AjaxCache.retrieve.mockResolvedValue({ '2026-09-01': 5 });
    window.gon = {
      dot_com: true,
      first_day_of_week: 0,
      features: { contributionMusicEasterEgg: true },
    };
    setUrl('https://gdk.test/root?play');
  });

  afterEach(() => {
    resetHTMLFixture();
    findModal()?.remove();
  });

  describe.each`
    calendar    | markup
    ${'Vue'}    | ${VUE_CALENDAR}
    ${'legacy'} | ${LEGACY_CALENDAR}
  `('with the $calendar activity calendar', ({ markup }) => {
    beforeEach(async () => {
      setHTMLFixture(markup);
      await initContributionMusic();
    });

    it('renders the modal', () => {
      expect(findModal()).not.toBe(null);
    });

    it('reads the same calendar JSON the graph does', () => {
      expect(mockRender).toHaveBeenCalledWith(
        expect.objectContaining({ calendarPath: '/users/root/calendar.json', username: 'root' }),
      );
    });
  });

  describe('without the ?play parameter', () => {
    beforeEach(async () => {
      setUrl('https://gdk.test/root');
      setHTMLFixture(VUE_CALENDAR);
      await initContributionMusic();
    });

    it('does nothing', () => {
      expect(findModal()).toBe(null);
    });
  });

  describe('on self-managed', () => {
    beforeEach(async () => {
      window.gon.dot_com = false;
      setHTMLFixture(VUE_CALENDAR);
      await initContributionMusic();
    });

    it('does nothing', () => {
      expect(findModal()).toBe(null);
    });
  });

  describe('with the contribution_music_easter_egg flag disabled', () => {
    beforeEach(async () => {
      window.gon.features.contributionMusicEasterEgg = false;
      setHTMLFixture(VUE_CALENDAR);
      await initContributionMusic();
    });

    it('does nothing', () => {
      expect(findModal()).toBe(null);
    });
  });

  // Regression guard: initVueActivityCalendar() mounts over
  // #js-vue-activity-calendar and Vue replaces it, so this must run first.
  describe('after the Vue activity calendar has mounted', () => {
    beforeEach(async () => {
      setHTMLFixture(VUE_CALENDAR);
      initVueActivityCalendar();
      await initContributionMusic();
    });

    it('is too late to find the calendar', () => {
      expect(findModal()).toBe(null);
    });
  });

  describe('when neither calendar is on the page', () => {
    beforeEach(async () => {
      setHTMLFixture('<div></div>');
      await initContributionMusic();
    });

    it('does nothing', () => {
      expect(findModal()).toBe(null);
    });
  });
});
