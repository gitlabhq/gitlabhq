import { GlDisclosureDropdownGroup, GlDisclosureDropdownItem } from '@gitlab/ui';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { shallowMount } from '@vue/test-utils';
import GlobalSearchDefaultIssuables from '~/super_sidebar/components/global_search/components/global_search_default_issuables.vue';
import SearchResultFocusLayover from '~/super_sidebar/components/global_search/components/global_search_focus_overlay.vue';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import {
  EVENT_CLICK_ISSUES_ASSIGNED_TO_ME_IN_COMMAND_PALETTE,
  EVENT_CLICK_ISSUES_I_CREATED_IN_COMMAND_PALETTE,
  EVENT_CLICK_MERGE_REQUESTS_ASSIGNED_TO_ME_IN_COMMAND_PALETTE,
  EVENT_CLICK_MERGE_REQUESTS_THAT_IM_A_REVIEWER_IN_COMMAND_PALETTE,
  EVENT_CLICK_MERGE_REQUESTS_I_CREATED_IN_COMMAND_PALETTE,
} from '~/super_sidebar/components/global_search/tracking_constants';
import {
  MOCK_SEARCH_CONTEXT,
  MOCK_PROJECT_SEARCH_CONTEXT,
  MOCK_GROUP_SEARCH_CONTEXT,
  MOCK_DEFAULT_SEARCH_OPTIONS,
} from '../mock_data';

Vue.use(Vuex);

describe('GlobalSearchDefaultPlaces', () => {
  let wrapper;

  const createComponent = ({
    searchContext = null,
    mockDefaultSearchOptions = [],
    ...options
  } = {}) => {
    const store = new Vuex.Store({
      state: {
        searchContext,
      },
      getters: {
        defaultSearchOptions: () => mockDefaultSearchOptions,
      },
    });

    wrapper = shallowMount(GlobalSearchDefaultIssuables, {
      store,
      stubs: {
        GlDisclosureDropdownGroup,
      },
      ...options,
    });
  };

  const findGroup = () => wrapper.findComponent(GlDisclosureDropdownGroup);
  const findItems = () => wrapper.findAllComponents(GlDisclosureDropdownItem);
  const findLayover = () => wrapper.findComponent(SearchResultFocusLayover);

  describe('given no contextSwitcherLinks', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders nothing', () => {
      expect(wrapper.find('*').exists()).toBe(false);
    });

    it('emits a nothing-to-render event', () => {
      expect(wrapper.emitted('nothing-to-render')).toEqual([[]]);
    });
  });

  describe('given some contextSwitcherLinks', () => {
    beforeEach(() => {
      createComponent({
        searchContext: MOCK_SEARCH_CONTEXT,
        mockDefaultSearchOptions: MOCK_DEFAULT_SEARCH_OPTIONS,
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
      expect(wrapper.text()).toContain('All GitLab');
    });

    it('passes attrs down', () => {
      const group = findGroup();
      expect(group.props('bordered')).toBe(true);
      expect(group.classes()).toContain('test-class');
    });

    it('renders the links', () => {
      const itemProps = findItems().wrappers.map((item) => item.props('item'));

      // Update the test expectation to match the new implementation
      expect(itemProps).toEqual(
        MOCK_DEFAULT_SEARCH_OPTIONS.map((item) => ({
          ...item,
          // Remove the extraAttrs field from the expectation
        })),
      );
    });

    it('renders the layover component', () => {
      expect(findLayover().exists()).toBe(true);
    });
  });

  describe('group name', () => {
    describe('in a project context', () => {
      beforeEach(() => {
        createComponent({
          searchContext: MOCK_PROJECT_SEARCH_CONTEXT,
          mockDefaultSearchOptions: MOCK_DEFAULT_SEARCH_OPTIONS,
        });
      });

      it('renders the expected header', () => {
        expect(wrapper.text()).toContain('MockProject');
      });
    });

    describe('in a group context', () => {
      beforeEach(() => {
        createComponent({
          searchContext: MOCK_GROUP_SEARCH_CONTEXT,
          mockDefaultSearchOptions: MOCK_DEFAULT_SEARCH_OPTIONS,
        });
      });

      it('renders the expected header', () => {
        expect(wrapper.text()).toContain('MockGroup');
      });
    });
  });

  describe('Track events', () => {
    beforeEach(() => {
      createComponent({
        searchContext: MOCK_PROJECT_SEARCH_CONTEXT,
        mockDefaultSearchOptions: MOCK_DEFAULT_SEARCH_OPTIONS,
      });
    });

    const { bindInternalEventDocument } = useMockInternalEventsTracking();

    it.each`
      eventTrigger                            | event
      ${'Issues assigned to me'}              | ${EVENT_CLICK_ISSUES_ASSIGNED_TO_ME_IN_COMMAND_PALETTE}
      ${"Issues I've created"}                | ${EVENT_CLICK_ISSUES_I_CREATED_IN_COMMAND_PALETTE}
      ${'Merge requests assigned to me'}      | ${EVENT_CLICK_MERGE_REQUESTS_ASSIGNED_TO_ME_IN_COMMAND_PALETTE}
      ${"Merge requests that I'm a reviewer"} | ${EVENT_CLICK_MERGE_REQUESTS_THAT_IM_A_REVIEWER_IN_COMMAND_PALETTE}
      ${"Merge requests I've created"}        | ${EVENT_CLICK_MERGE_REQUESTS_I_CREATED_IN_COMMAND_PALETTE}
    `('triggers and tracks command dropdown $event', ({ eventTrigger, event }) => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      // Update to emit the action event from each dropdown item rather than the group
      findItems().wrappers.forEach((item) => {
        if (item.props('item')?.text === eventTrigger) {
          item.vm.$emit('action', { text: eventTrigger });
        }
      });
      expect(trackEventSpy).toHaveBeenCalledWith(event, {}, undefined);
    });
  });
});
