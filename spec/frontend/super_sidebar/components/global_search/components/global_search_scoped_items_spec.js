import { GlDisclosureDropdownGroup, GlDisclosureDropdownItem } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { trimText } from 'helpers/text_helper';
import GlobalSearchScopedItems from '~/super_sidebar/components/global_search/components/global_search_scoped_items.vue';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import {
  EVENT_CLICK_ALL_GITLAB_SCOPED_SEARCH_TO_ADVANCED_SEARCH,
  EVENT_CLICK_GROUP_SCOPED_SEARCH_TO_ADVANCED_SEARCH,
  EVENT_CLICK_PROJECT_SCOPED_SEARCH_TO_ADVANCED_SEARCH,
} from '~/super_sidebar/components/global_search/tracking_constants';
import {
  SCOPE_SEARCH_ALL,
  SCOPE_SEARCH_GROUP,
  SCOPE_SEARCH_PROJECT,
} from '~/super_sidebar/components/global_search/command_palette/constants';
import {
  MOCK_SEARCH,
  MOCK_SCOPED_SEARCH_GROUP,
  MOCK_GROUPED_AUTOCOMPLETE_OPTIONS,
} from '../mock_data';

Vue.use(Vuex);

describe('GlobalSearchScopedItems', () => {
  let wrapper;

  const createComponent = (initialState, mockGetters, props) => {
    const store = new Vuex.Store({
      state: {
        search: MOCK_SEARCH,
        ...initialState,
      },
      getters: {
        scopedSearchGroup: () => MOCK_SCOPED_SEARCH_GROUP,
        autocompleteGroupedSearchOptions: () => MOCK_GROUPED_AUTOCOMPLETE_OPTIONS,
        ...mockGetters,
      },
    });

    wrapper = mount(GlobalSearchScopedItems, {
      store,
      propsData: {
        ...props,
      },
      stubs: {
        GlDisclosureDropdownGroup,
        GlDisclosureDropdownItem,
      },
    });
  };

  const findGroup = () => wrapper.findComponent(GlDisclosureDropdownGroup);
  const findItems = () => wrapper.findAllComponents(GlDisclosureDropdownItem);
  const findItemsText = () => findItems().wrappers.map((w) => trimText(w.text()));
  const findItemLinks = () => findItems().wrappers.map((w) => w.find('a').attributes('href'));

  describe('Search results scoped items', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders item for each item in scopedSearchGroup', () => {
      expect(findItems()).toHaveLength(MOCK_SCOPED_SEARCH_GROUP.items.length);
    });

    it('renders titles correctly', () => {
      findItemsText().forEach((title, i) => {
        expect(title).toContain(
          MOCK_SCOPED_SEARCH_GROUP.items[i].scope || MOCK_SCOPED_SEARCH_GROUP.items[i].description,
        );
      });
    });

    it('renders links correctly', () => {
      const expectedLinks = MOCK_SCOPED_SEARCH_GROUP.items.map((o) => o.href);
      expect(findItemLinks()).toStrictEqual(expectedLinks);
    });

    describe('tracking', () => {
      const { bindInternalEventDocument } = useMockInternalEventsTracking();

      it.each`
        action                  | event
        ${SCOPE_SEARCH_ALL}     | ${EVENT_CLICK_ALL_GITLAB_SCOPED_SEARCH_TO_ADVANCED_SEARCH}
        ${SCOPE_SEARCH_GROUP}   | ${EVENT_CLICK_GROUP_SCOPED_SEARCH_TO_ADVANCED_SEARCH}
        ${SCOPE_SEARCH_PROJECT} | ${EVENT_CLICK_PROJECT_SCOPED_SEARCH_TO_ADVANCED_SEARCH}
      `("triggers tracking event '$event' after emiting action '$action'", ({ action, event }) => {
        const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
        findGroup().vm.$emit('action', { text: action });
        expect(trackEventSpy).toHaveBeenCalledWith(event, {}, undefined);
      });
    });
  });
});
