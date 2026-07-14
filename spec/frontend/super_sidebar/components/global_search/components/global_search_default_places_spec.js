import { GlDisclosureDropdownGroup, GlDisclosureDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import GlobalSearchDefaultPlaces from '~/super_sidebar/components/global_search/components/global_search_default_places.vue';
import SearchResultFocusLayover from '~/super_sidebar/components/global_search/components/global_search_focus_overlay.vue';
import {
  EVENT_CLICK_YOUR_WORK_IN_COMMAND_PALETTE,
  EVENT_CLICK_EXPLORE_IN_COMMAND_PALETTE,
  EVENT_CLICK_PROFILE_IN_COMMAND_PALETTE,
  EVENT_CLICK_PREFERENCES_IN_COMMAND_PALETTE,
} from '~/super_sidebar/components/global_search/tracking_constants';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';

const makeItem = ({ text, href, dataMethod }) => ({
  text,
  href,
  extraAttrs: {
    class: 'show-focus-layover',
    'data-track-action': 'click_command_palette_item',
    'data-track-extra': JSON.stringify({ title: text }),
    'data-track-label': 'item_without_id',
    'data-track-property': 'nav_panel_unknown',
    'data-testid': 'places-item-link',
    'data-qa-places-item': text,
    ...(dataMethod ? { 'data-method': dataMethod } : {}),
  },
});

describe('GlobalSearchDefaultPlaces', () => {
  let wrapper;

  const createComponent = ({ isLoggedIn = true, showAdminAreaLink = false, attrs } = {}) => {
    window.gon.current_user_id = isLoggedIn ? 123 : null;

    wrapper = shallowMount(GlobalSearchDefaultPlaces, {
      provide: {
        showAdminAreaLink,
      },
      attrs,
      stubs: {
        GlDisclosureDropdownGroup,
      },
    });
  };

  const findGroup = () => wrapper.findComponent(GlDisclosureDropdownGroup);
  const findItems = () => wrapper.findAllComponents(GlDisclosureDropdownItem);
  const findLayover = () => wrapper.findComponent(SearchResultFocusLayover);

  describe('when logged out', () => {
    beforeEach(() => {
      createComponent({ isLoggedIn: false });
    });

    it('renders only the Explore link', () => {
      const itemProps = findItems().wrappers.map((item) => item.props('item'));

      expect(itemProps).toEqual([makeItem({ text: 'Explore', href: '/explore' })]);
    });
  });

  describe('when logged in', () => {
    beforeEach(() => {
      createComponent({
        attrs: {
          bordered: true,
          class: 'test-class',
        },
      });
    });

    it('renders a disclosure dropdown group', () => {
      expect(findGroup().exists()).toBe(true);
    });

    it('renders the expected header', () => {
      expect(wrapper.text()).toContain('Places');
    });

    it('passes attrs down', () => {
      const group = findGroup();
      expect(group.props('bordered')).toBe(true);
      expect(group.classes()).toContain('test-class');
    });

    it('renders the links', () => {
      const itemProps = findItems().wrappers.map((item) => item.props('item'));

      expect(itemProps).toEqual([
        makeItem({ text: 'Your work', href: '/' }),
        makeItem({ text: 'Explore', href: '/explore' }),
        makeItem({ text: 'Profile', href: '/-/user_settings/profile' }),
        makeItem({ text: 'Preferences', href: '/-/profile/preferences' }),
      ]);
    });

    it('renders the layover component', () => {
      expect(findLayover().exists()).toBe(true);
    });

    describe('tracking', () => {
      const { bindInternalEventDocument } = useMockInternalEventsTracking();

      it.each`
        action           | event
        ${'Your work'}   | ${EVENT_CLICK_YOUR_WORK_IN_COMMAND_PALETTE}
        ${'Explore'}     | ${EVENT_CLICK_EXPLORE_IN_COMMAND_PALETTE}
        ${'Profile'}     | ${EVENT_CLICK_PROFILE_IN_COMMAND_PALETTE}
        ${'Preferences'} | ${EVENT_CLICK_PREFERENCES_IN_COMMAND_PALETTE}
      `("triggers tracking event '$event' after emiting action '$action'", ({ action, event }) => {
        const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
        findGroup().vm.$emit('action', { text: action });
        expect(trackEventSpy).toHaveBeenCalledWith(event, {}, undefined);
      });
    });
  });

  describe('when showAdminAreaLink is true', () => {
    beforeEach(() => {
      createComponent({ showAdminAreaLink: true });
    });

    it('renders the Admin area link', () => {
      const itemProps = findItems().wrappers.map((item) => item.props('item'));

      expect(itemProps).toContainEqual(makeItem({ text: 'Admin area', href: '/admin' }));
    });
  });
});
