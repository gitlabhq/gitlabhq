import { GlCollapsibleListbox } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import SidebarPreferences from '~/super_sidebar/components/sidebar_preferences.vue';
import {
  SIDEBAR_NAV_MODE_PINNED_ONLY,
  SIDEBAR_NAV_MODE_ALL_CATEGORIES,
  SIDEBAR_NAV_MODE_GROUPED_PINS,
} from '~/super_sidebar/constants';
import { EVENT_SELECT_SIDEBAR_NAVIGATION_MODE_IN_SIDEBAR_PREFERENCES } from '~/super_sidebar/tracking_constants';

describe('SidebarPreferences component', () => {
  let wrapper;

  const createWrapper = ({ props = {}, provide = {} } = {}) => {
    wrapper = mountExtended(SidebarPreferences, {
      propsData: props,
      provide: { panelType: 'project', ...provide },
    });
  };

  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findToggleButton = () => wrapper.findByTestId('sidebar-preferences').find('button');
  const selectMode = (mode) => findListbox().vm.$emit('select', mode);

  describe('rendering', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders the listbox with the ellipsis trigger button', () => {
      expect(findListbox().exists()).toBe(true);
      expect(findToggleButton().exists()).toBe(true);
    });

    it('offers the three modes, ordered least to most expansive, with subtext', () => {
      expect(findListbox().props('items')).toEqual([
        { value: SIDEBAR_NAV_MODE_PINNED_ONLY, text: 'Flat', description: 'Pinned only' },
        {
          value: SIDEBAR_NAV_MODE_GROUPED_PINS,
          text: 'Organized',
          description: 'Pinned in categories',
        },
        {
          value: SIDEBAR_NAV_MODE_ALL_CATEGORIES,
          text: 'Everything',
          description: 'All categories',
        },
      ]);
    });

    it('renders each item as a primary label with descriptive subtext', async () => {
      // The list only renders once the dropdown is open.
      await findToggleButton().trigger('click');

      const firstItem = wrapper.findByTestId('listbox-item-pinned_only');

      expect(firstItem.text()).toContain('Flat');
      expect(firstItem.text()).toContain('Pinned only');
    });
  });

  describe('selected state', () => {
    it('marks the current mode as selected in the listbox', () => {
      createWrapper({ props: { mode: SIDEBAR_NAV_MODE_ALL_CATEGORIES } });

      expect(findListbox().props('selected')).toBe(SIDEBAR_NAV_MODE_ALL_CATEGORIES);
    });
  });

  describe('emitted events', () => {
    it('emits select with the chosen mode', () => {
      createWrapper({ props: { mode: SIDEBAR_NAV_MODE_PINNED_ONLY } });
      selectMode(SIDEBAR_NAV_MODE_GROUPED_PINS);

      expect(wrapper.emitted('select')).toEqual([[SIDEBAR_NAV_MODE_GROUPED_PINS]]);
    });

    it('does not emit when the chosen mode is already selected', () => {
      createWrapper({ props: { mode: SIDEBAR_NAV_MODE_GROUPED_PINS } });
      selectMode(SIDEBAR_NAV_MODE_GROUPED_PINS);

      expect(wrapper.emitted('select')).toBeUndefined();
    });
  });

  describe('internal events tracking', () => {
    const { bindInternalEventDocument } = useMockInternalEventsTracking();

    // The mixin forwards a third `category` arg (undefined) to trackEvent.
    const CATEGORY = undefined;

    it('tracks the selected mode as the event property, labelled with the panel type', () => {
      createWrapper({
        props: { mode: SIDEBAR_NAV_MODE_PINNED_ONLY },
        provide: { panelType: 'group' },
      });
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      selectMode(SIDEBAR_NAV_MODE_GROUPED_PINS);

      expect(trackEventSpy).toHaveBeenCalledWith(
        EVENT_SELECT_SIDEBAR_NAVIGATION_MODE_IN_SIDEBAR_PREFERENCES,
        { label: 'group', property: SIDEBAR_NAV_MODE_GROUPED_PINS },
        CATEGORY,
      );
    });

    it('does not track when the selected mode is unchanged', () => {
      createWrapper({
        props: { mode: SIDEBAR_NAV_MODE_GROUPED_PINS },
        provide: { panelType: 'group' },
      });
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      selectMode(SIDEBAR_NAV_MODE_GROUPED_PINS);

      expect(trackEventSpy).not.toHaveBeenCalled();
    });
  });
});
