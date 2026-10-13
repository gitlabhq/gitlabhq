import { nextTick } from 'vue';
import { getByRole } from '@testing-library/dom';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import AjaxCache from '~/lib/utils/ajax_cache';
import { nDaysBefore, toISODateFormat } from '~/lib/utils/datetime_utility';
import ContributionMusicApp from '~/easter_eggs/contribution_music/components/contribution_music_app.vue';
import { I18N } from '~/easter_eggs/contribution_music/constants';

jest.mock('~/lib/utils/ajax_cache');
// jsdom has no canvas or Web Audio, so the drawing and the player are stubbed.
jest.mock('~/easter_eggs/contribution_music/video', () => ({
  ...jest.requireActual('~/easter_eggs/contribution_music/video'),
  drawLogo: jest.fn(),
  drawQrCode: jest.fn(),
  drawVideoPreview: jest.fn(),
}));
jest.mock('~/easter_eggs/contribution_music/visualizer', () => ({
  createVisualizer: jest.fn(),
  prefersReducedMotion: () => true,
}));
jest.mock('~/easter_eggs/contribution_music/synth', () => ({
  ...jest.requireActual('~/easter_eggs/contribution_music/synth'),
  createPlayer: () => ({
    start: jest.fn().mockResolvedValue(),
    stop: jest.fn(),
    destroy: jest.fn(),
    readSpectrum: jest.fn(),
  }),
}));

// GlModal portals its content out of the component root, so these read the
// document rather than the wrapper.
const findCells = () => [...document.querySelectorAll('[id^="contribution-music-cell-"]')];
const findDays = () => findCells().filter((cell) => cell.tagName === 'BUTTON');
const findPadding = () => findCells().filter((cell) => cell.tagName === 'DIV');
const findTabStops = () => findDays().filter((cell) => cell.getAttribute('tabindex') === '0');

describe('ContributionMusicApp grid', () => {
  beforeEach(async () => {
    // The grid only renders when audio is available, which jsdom has not got.
    window.AudioContext = jest.fn();
    // Enough active days for a song rather than the empty state.
    const today = new Date();
    AjaxCache.retrieve.mockResolvedValue(
      Object.fromEntries([0, 1, 2, 3].map((n) => [toISODateFormat(nDaysBefore(today, n)), 12])),
    );

    mountExtended(ContributionMusicApp, {
      propsData: {
        calendarPath: '/users/root/calendar.json',
        utcOffset: 0,
        firstDayOfWeek: 0,
        username: 'root',
      },
      attachTo: document.body,
    });

    await waitForPromises();
    // The grid replaces the intro once the song is played.
    getByRole(document.body, 'button', { name: I18N.play }).click();
    await waitForPromises();
  });

  afterEach(() => {
    delete window.AudioContext;
  });

  // The same 12 months as the profile calendar, up to today (the spec clock's July 6, 2020).
  it('renders the last 12 months', () => {
    expect(findDays()[0].getAttribute('aria-label')).toContain('July 6, 2019');
    expect(findDays().at(-1).getAttribute('aria-label')).toContain('July 6, 2020');
  });

  it('is a single tab stop', () => {
    expect(findTabStops()).toHaveLength(1);
  });

  it('describes each day for screen readers', () => {
    expect(findDays()[0].getAttribute('aria-label')).toMatch(/contribution/);
  });

  it('hides the padding cells from assistive technology', () => {
    findPadding().forEach((cell) => {
      expect(cell.getAttribute('aria-hidden')).toBe('true');
      expect(cell.getAttribute('aria-label')).toBe(null);
    });
  });

  it.each`
    key             | description
    ${'ArrowRight'} | ${'the next week'}
    ${'ArrowDown'}  | ${'the next day'}
  `('moves the tab stop to $description on $key', async ({ key }) => {
    const before = findTabStops()[0].id;

    findTabStops()[0].dispatchEvent(new KeyboardEvent('keydown', { key, bubbles: true }));
    await nextTick();

    expect(findTabStops()).toHaveLength(1);
    expect(findTabStops()[0].id).not.toBe(before);
  });
});
