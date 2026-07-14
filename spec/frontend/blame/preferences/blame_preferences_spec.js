import { GlDisclosureDropdown, GlToggle } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BlamePreferences from '~/blame/preferences/blame_preferences.vue';
import * as urlUtils from '~/lib/utils/url_utility';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  getParameterByName: jest.fn(),
  setUrlParams: jest.fn(),
  visitUrl: jest.fn(),
}));

jest.mock('~/helpers/help_page_helper', () => ({
  helpPagePath: jest.fn().mockReturnValue('/help/page'),
}));

describe('BlamePreferences', () => {
  let wrapper;

  const createComponent = ({ hasRevsFile = true, showAgeIndicatorToggle = true } = {}) => {
    wrapper = shallowMountExtended(BlamePreferences, {
      propsData: { hasRevsFile, showAgeIndicatorToggle },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findAgeIndicatorToggle = () => wrapper.findComponent(GlToggle);
  const findIgnoreRevsCheckbox = () => wrapper.findByTestId('ignore-revs-checkbox');
  const findIgnoreRevsItem = () => wrapper.findByTestId('ignore-revs-item');
  const findLearnToIgnoreItem = () => wrapper.findByTestId('learn-to-ignore-item');

  const { bindInternalEventDocument } = useMockInternalEventsTracking();

  beforeEach(() => {
    jest.clearAllMocks();
    localStorage.clear();
  });

  describe('dropdown rendering', () => {
    beforeEach(() => createComponent());

    it('renders as icon-only dropdown', () => {
      expect(findDropdown().props('icon')).toBe('preferences');
      expect(findDropdown().props('textSrOnly')).toBe(true);
    });

    it('has accessible toggle text', () => {
      expect(findDropdown().props('toggleText')).toBe('Blame preferences');
    });
  });

  describe('age indicator toggle', () => {
    it('defaults to off', () => {
      createComponent();

      expect(findAgeIndicatorToggle().props('value')).toBe(false);
    });

    it('reads initial state from localStorage', () => {
      localStorage.setItem('blame_show_age_indicator', 'true');
      createComponent();

      expect(findAgeIndicatorToggle().props('value')).toBe(true);
    });

    it('persists to localStorage on toggle', async () => {
      createComponent();
      await findAgeIndicatorToggle().vm.$emit('change');

      expect(localStorage.getItem('blame_show_age_indicator')).toBe('true');
    });

    it('emits toggle-age-indicator event', async () => {
      createComponent();
      await findAgeIndicatorToggle().vm.$emit('change');

      expect(wrapper.emitted('toggle-age-indicator')).toEqual([[false], [true]]);
    });

    it('tracks the toggle event with property show', async () => {
      createComponent();
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      await findAgeIndicatorToggle().vm.$emit('change');

      expect(trackEventSpy).toHaveBeenCalledWith(
        'toggle_inline_blame_age_indicator_on_blob_page',
        { property: 'show' },
        undefined,
      );
    });

    it('tracks the toggle event with property hide', async () => {
      localStorage.setItem('blame_show_age_indicator', 'true');
      createComponent();
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      await findAgeIndicatorToggle().vm.$emit('change');

      expect(trackEventSpy).toHaveBeenCalledWith(
        'toggle_inline_blame_age_indicator_on_blob_page',
        { property: 'hide' },
        undefined,
      );
    });

    it('renders with label on the left', () => {
      createComponent();

      expect(findAgeIndicatorToggle().props('labelPosition')).toBe('left');
      expect(findAgeIndicatorToggle().props('label')).toBe('Show age indicator legend');
    });

    it('hides toggle when showAgeIndicatorToggle is false', () => {
      createComponent({ showAgeIndicatorToggle: false });

      expect(findAgeIndicatorToggle().exists()).toBe(false);
    });
  });

  describe('when revs file exists', () => {
    beforeEach(() => createComponent());

    it('shows ignore revs checkbox inside a dropdown item', () => {
      expect(findIgnoreRevsItem().exists()).toBe(true);
      expect(findIgnoreRevsCheckbox().text()).toBe('Ignore specific revisions');
    });

    it('renders checkbox with pointer-events-none', () => {
      expect(findIgnoreRevsCheckbox().classes()).toContain('gl-pointer-events-none');
    });

    it('shows learn more button', () => {
      expect(findLearnToIgnoreItem().text()).toBe('Learn to ignore specific revisions');
    });
  });

  describe('when revs file does not exist', () => {
    beforeEach(() => createComponent({ hasRevsFile: false }));

    it('does not show ignore revs checkbox', () => {
      expect(findIgnoreRevsCheckbox().exists()).toBe(false);
    });

    it('does not show ignore revs dropdown item', () => {
      expect(findIgnoreRevsItem().exists()).toBe(false);
    });

    it('shows learn to ignore button', () => {
      expect(findLearnToIgnoreItem().text()).toBe('Learn to ignore specific revisions');
    });
  });

  describe('ignore revs functionality', () => {
    const mockUrl = 'mock-url?ignore_revs=true';

    beforeEach(() => {
      urlUtils.setUrlParams.mockReturnValue(mockUrl);
      createComponent();
    });

    it('toggles isIgnoring and navigates when item action is triggered', async () => {
      await findIgnoreRevsItem().vm.$emit('action');

      expect(urlUtils.setUrlParams).toHaveBeenCalledWith({ ignore_revs: true });
      expect(urlUtils.visitUrl).toHaveBeenCalledWith(mockUrl);
      expect(findDropdown().props('loading')).toBe(true);
    });

    it('toggles isIgnoring from true to false', async () => {
      urlUtils.getParameterByName.mockReturnValue('true');
      createComponent();

      await findIgnoreRevsItem().vm.$emit('action');

      expect(urlUtils.setUrlParams).toHaveBeenCalledWith({ ignore_revs: false });
    });

    it('shows checked state when URL param is true', () => {
      urlUtils.getParameterByName.mockReturnValue('true');
      createComponent();

      expect(findIgnoreRevsCheckbox().attributes('checked')).toBe('true');
    });

    it('shows unchecked state when URL param is absent', () => {
      urlUtils.getParameterByName.mockReturnValue(null);
      createComponent();

      expect(findIgnoreRevsCheckbox().attributes('checked')).toBeUndefined();
    });
  });

  describe('docs link functionality', () => {
    const mockDocsUrl = '/help/page';

    it('navigates to docs when learn more is clicked with revs file', async () => {
      createComponent({ hasRevsFile: true });
      await findLearnToIgnoreItem().vm.$emit('action');

      expect(urlUtils.visitUrl).toHaveBeenCalledWith(mockDocsUrl);
    });

    it('navigates to docs when learn to ignore is clicked without revs file', async () => {
      createComponent({ hasRevsFile: false });
      await findLearnToIgnoreItem().vm.$emit('action');

      expect(urlUtils.visitUrl).toHaveBeenCalledWith(mockDocsUrl);
    });
  });
});
