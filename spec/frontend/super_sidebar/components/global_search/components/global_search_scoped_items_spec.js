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
  USER_HANDLE,
} from '~/super_sidebar/components/global_search/command_palette/constants';
import { injectRegexSearch, injectUsersScope } from '~/search/store/utils';
import {
  MOCK_SEARCH,
  MOCK_SCOPED_SEARCH_GROUP,
  MOCK_GROUPED_AUTOCOMPLETE_OPTIONS,
} from '../mock_data';

jest.mock('~/search/store/utils', () => ({
  injectRegexSearch: jest.fn((href) => `${href}/injected-regex`),
  injectUsersScope: jest.fn((href) => `${href}/injected-users-scope`),
}));

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

  describe('when render scoped items', () => {
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
      const expectedLinks = ['/mock-project/injected-regex', '/mock-group', '/'];
      expect(findItemLinks()).toStrictEqual(expectedLinks);
    });

    describe('when tracking', () => {
      const { bindInternalEventDocument } = useMockInternalEventsTracking();

      it.each`
        action                  | event
        ${SCOPE_SEARCH_ALL}     | ${EVENT_CLICK_ALL_GITLAB_SCOPED_SEARCH_TO_ADVANCED_SEARCH}
        ${SCOPE_SEARCH_GROUP}   | ${EVENT_CLICK_GROUP_SCOPED_SEARCH_TO_ADVANCED_SEARCH}
        ${SCOPE_SEARCH_PROJECT} | ${EVENT_CLICK_PROJECT_SCOPED_SEARCH_TO_ADVANCED_SEARCH}
      `("triggers '$event' with '$action'", ({ action, event }) => {
        const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
        findGroup().vm.$emit('action', { text: action });
        expect(trackEventSpy).toHaveBeenCalledWith(event, {}, undefined);
      });
    });
  });

  describe('when using injectSearchPropsToHref', () => {
    beforeEach(() => {
      injectRegexSearch.mockClear();
      injectUsersScope.mockClear();
    });

    it('applies injectRegexSearch when item.text is SCOPE_SEARCH_PROJECT', () => {
      const mockSearchGroup = {
        name: 'Test Group',
        items: [
          {
            text: SCOPE_SEARCH_PROJECT,
            href: '/test-project-href',
            description: 'Search in project',
          },
        ],
      };

      createComponent({}, { scopedSearchGroup: () => mockSearchGroup });

      expect(injectRegexSearch).toHaveBeenCalledWith('/test-project-href');
      expect(findItemLinks()[0]).toBe('/test-project-href/injected-regex');
    });

    it('applies injectUsersScope when commandChar is USER_HANDLE', () => {
      const mockSearchGroup = {
        name: 'Test Group',
        items: [
          {
            text: 'some-other-text',
            href: '/test-users-href',
            description: 'Search for users',
          },
        ],
      };

      createComponent({ commandChar: USER_HANDLE }, { scopedSearchGroup: () => mockSearchGroup });

      expect(injectUsersScope).toHaveBeenCalledWith('/test-users-href');
      expect(findItemLinks()[0]).toBe('/test-users-href/injected-users-scope');
    });

    it('returns original href when no conditions are met', () => {
      const mockSearchGroup = {
        name: 'Test Group',
        items: [
          {
            text: 'some-random-text',
            href: '/original-href',
            description: 'Regular search',
          },
        ],
      };

      createComponent({ commandChar: '>' }, { scopedSearchGroup: () => mockSearchGroup });

      expect(injectRegexSearch).not.toHaveBeenCalled();
      expect(injectUsersScope).not.toHaveBeenCalled();

      expect(findItemLinks()[0]).toBe('/original-href');
    });
  });
});
