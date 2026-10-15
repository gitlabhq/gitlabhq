import { GlCollapsibleListbox } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import SidebarPreferences from '~/super_sidebar/components/sidebar_preferences.vue';
import { SIDEBAR_NAV_MODE_COMPACT, SIDEBAR_NAV_MODE_FULL } from '~/super_sidebar/constants';
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

    it('offers the two modes, ordered least to most expansive, with subtext', () => {
      expect(findListbox().props('items')).toEqual([
        { value: 'compact', text: 'Compact', description: 'Pinned only' },
        { value: 'all_categories', text: 'Full', description: 'Pinned and all categories' },
      ]);
    });

    it('selects compact by default', () => {
      expect(findListbox().props('selected')).toBe('compact');
    });

    it('renders each item as a primary label with descriptive subtext', async () => {
      // The list only renders once the dropdown is open.
      await findToggleButton().trigger('click');

      const firstItem = wrapper.findByTestId('listbox-item-compact');

      expect(firstItem.text()).toContain('Compact');
      expect(firstItem.text()).toContain('Pinned only');
    });
  });

  describe('selected state', () => {
    it('marks the current mode as selected in the listbox', () => {
      createWrapper({ props: { mode: SIDEBAR_NAV_MODE_FULL } });

      expect(findListbox().props('selected')).toBe('all_categories');
    });
  });

  describe('emitted events', () => {
    it('emits select with the chosen mode', () => {
      createWrapper({ props: { mode: SIDEBAR_NAV_MODE_COMPACT } });
      selectMode(SIDEBAR_NAV_MODE_FULL);

      expect(wrapper.emitted('select')).toEqual([['all_categories']]);
    });

    it('does not emit when the chosen mode is already selected', () => {
      createWrapper({ props: { mode: SIDEBAR_NAV_MODE_FULL } });
      selectMode(SIDEBAR_NAV_MODE_FULL);

      expect(wrapper.emitted('select')).toBeUndefined();
    });
  });

  describe('internal events tracking', () => {
    const { bindInternalEventDocument } = useMockInternalEventsTracking();

    // The mixin forwards a third `category` arg (undefined) to trackEvent.
    const CATEGORY = undefined;

    it('tracks the selected mode as the event property, labelled with the panel type', () => {
      createWrapper({
        props: { mode: SIDEBAR_NAV_MODE_COMPACT },
        provide: { panelType: 'group' },
      });
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      selectMode(SIDEBAR_NAV_MODE_FULL);

      expect(trackEventSpy).toHaveBeenCalledWith(
        EVENT_SELECT_SIDEBAR_NAVIGATION_MODE_IN_SIDEBAR_PREFERENCES,
        { label: 'group', property: 'all_categories' },
        CATEGORY,
      );
    });

    it('does not track when the selected mode is unchanged', () => {
      createWrapper({
        props: { mode: SIDEBAR_NAV_MODE_COMPACT },
        provide: { panelType: 'group' },
      });
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      selectMode(SIDEBAR_NAV_MODE_COMPACT);

      expect(trackEventSpy).not.toHaveBeenCalled();
    });
  });
});
