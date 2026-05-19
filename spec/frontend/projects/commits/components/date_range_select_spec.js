import { GlBadge, GlDisclosureDropdown } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { resetHTMLFixture, setHTMLFixture } from 'helpers/fixtures';
import setWindowLocation from 'helpers/set_window_location_helper';
import { newDate } from '~/lib/utils/datetime_utility';
import { visitUrl } from '~/lib/utils/url_utility';
import DateRangeSelect from '~/projects/commits/components/date_range_select.vue';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

const COMMITS_PATH = '/group/project/-/commits/main';

describe('DateRangeSelect', () => {
  let wrapper;

  const createComponent = () => {
    setHTMLFixture('<input id="commits-search" type="text" />');

    wrapper = mountExtended(DateRangeSelect, {
      propsData: { commitsPath: COMMITS_PATH },
    });
  };

  afterEach(() => {
    resetHTMLFixture();
  });

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findBadges = () => wrapper.findAllComponents(GlBadge);
  const findApplyButton = () => wrapper.findByTestId('apply-date-filters');
  const findClearButton = () => wrapper.findByTestId('clear-date-filters');
  const findCommittedAfterInput = () => wrapper.findByTestId('committed-after-input');
  const findCommittedBeforeInput = () => wrapper.findByTestId('committed-before-input');

  const setCommittedAfter = (date) => findCommittedAfterInput().vm.$emit('input', newDate(date));
  const setCommittedBefore = (date) => findCommittedBeforeInput().vm.$emit('input', newDate(date));

  beforeEach(() => {
    createComponent();
  });

  it('passes auto-close false to the dropdown', () => {
    expect(findDropdown().props('autoClose')).toBe(false);
  });

  describe('when no date filters are active', () => {
    it('renders no badges', () => {
      expect(findBadges()).toHaveLength(0);
    });

    it('does not render the clear button', () => {
      expect(findClearButton().exists()).toBe(false);
    });

    describe('after the user picks a date in the form but before applying', () => {
      beforeEach(async () => {
        await setCommittedAfter('2025-01-01');
        await setCommittedBefore('2025-12-31');
      });

      it('does not render any badges', () => {
        expect(findBadges()).toHaveLength(0);
      });

      it('does not render the clear button', () => {
        expect(findClearButton().exists()).toBe(false);
      });
    });
  });

  describe('when committed_after is set in the URL', () => {
    beforeEach(() => {
      setWindowLocation('?committed_after=2025-01-01');
      createComponent();
    });

    it('renders a per-filter badge containing the date and a summary badge', () => {
      const badges = findBadges();
      expect(badges).toHaveLength(2);
      expect(badges.at(0).text()).toBe('1 filter applied');
      expect(badges.at(1).text()).toContain('2025-01-01');
    });

    it('renders the clear button', () => {
      expect(findClearButton().exists()).toBe(true);
    });
  });

  describe('when committed_before is set in the URL', () => {
    beforeEach(() => {
      setWindowLocation('?committed_before=2025-12-31');
      createComponent();
    });

    it('renders a per-filter badge containing the date and a summary badge', () => {
      const badges = findBadges();
      expect(badges).toHaveLength(2);
      expect(badges.at(0).text()).toBe('1 filter applied');
      expect(badges.at(1).text()).toContain('2025-12-31');
    });
  });

  describe('when both date filters are set in the URL', () => {
    beforeEach(() => {
      setWindowLocation('?committed_after=2025-01-01&committed_before=2025-12-31');
      createComponent();
    });

    it('renders a per-filter badge for each date plus a summary badge', () => {
      const badges = findBadges();
      expect(badges).toHaveLength(3);
      expect(badges.at(0).text()).toBe('2 filters applied');
    });

    it('renders the clear button', () => {
      expect(findClearButton().exists()).toBe(true);
    });

    it('disables the commits-search input with a tooltip', () => {
      const input = document.querySelector('#commits-search');
      expect(input.hasAttribute('disabled')).toBe(true);
      expect(input.getAttribute('title')).toBe(
        'Searching by both date and message is currently not supported.',
      );
    });
  });

  describe('when searching by commit message', () => {
    beforeEach(() => {
      setWindowLocation('?search=refactor');
      createComponent();
    });

    it('disables the dropdown', () => {
      expect(findDropdown().props('disabled')).toBe(true);
    });

    it('shows a tooltip explaining why the dropdown is disabled', () => {
      expect(wrapper.attributes('title')).toBe(
        'Searching by both date and message is currently not supported.',
      );
    });
  });

  describe('when the user types into the commits search input', () => {
    let commitsSearchInput;

    beforeEach(() => {
      jest.useFakeTimers();
      createComponent();
      commitsSearchInput = document.querySelector('#commits-search');
    });

    afterEach(() => {
      jest.useRealTimers();
    });

    it('disables the dropdown after typing', async () => {
      commitsSearchInput.value = 'foo';
      commitsSearchInput.dispatchEvent(new Event('keyup'));
      jest.runAllTimers();
      await nextTick();

      expect(findDropdown().props('disabled')).toBe(true);
    });

    it('re-enables the dropdown when the input is cleared', async () => {
      commitsSearchInput.value = 'foo';
      commitsSearchInput.dispatchEvent(new Event('keyup'));
      jest.runAllTimers();
      await nextTick();

      commitsSearchInput.value = '';
      commitsSearchInput.dispatchEvent(new Event('keyup'));
      jest.runAllTimers();
      await nextTick();

      expect(findDropdown().props('disabled')).toBe(false);
    });

    it('removes the keyup listener when the component is destroyed', () => {
      const removeEventListenerSpy = jest.spyOn(commitsSearchInput, 'removeEventListener');

      wrapper.destroy();

      expect(removeEventListenerSpy).toHaveBeenCalledWith('keyup', expect.any(Function));
    });
  });

  describe('applyFilters', () => {
    it('navigates with both date params when both are set', async () => {
      await setCommittedAfter('2025-01-01');
      await setCommittedBefore('2025-12-31');
      await findApplyButton().trigger('click');

      expect(visitUrl).toHaveBeenCalledWith(
        `${COMMITS_PATH}?committed_after=2025-01-01&committed_before=2025-12-31`,
      );
    });

    it('navigates to base path when no dates are set', async () => {
      await findApplyButton().trigger('click');

      expect(visitUrl).toHaveBeenCalledWith(COMMITS_PATH);
    });

    it('preserves existing author param', async () => {
      setWindowLocation('?author=testuser');
      createComponent();
      await setCommittedAfter('2025-01-01');
      await findApplyButton().trigger('click');

      expect(visitUrl).toHaveBeenCalledWith(
        `${COMMITS_PATH}?author=testuser&committed_after=2025-01-01`,
      );
    });
  });

  describe('clearFilters', () => {
    beforeEach(() => {
      setWindowLocation('?committed_after=2025-01-01&committed_before=2025-12-31');
      createComponent();
    });

    it('navigates to base path without date params', async () => {
      await findClearButton().trigger('click');

      expect(visitUrl).toHaveBeenCalledWith(COMMITS_PATH);
    });

    it('preserves existing author param', async () => {
      setWindowLocation('?author=testuser&committed_after=2025-01-01');
      createComponent();
      await findClearButton().trigger('click');

      expect(visitUrl).toHaveBeenCalledWith(`${COMMITS_PATH}?author=testuser`);
    });
  });
});
