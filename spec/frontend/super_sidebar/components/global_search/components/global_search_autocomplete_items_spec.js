import {
  GlDisclosureDropdownGroup,
  GlDisclosureDropdownItem,
  GlLoadingIcon,
  GlAvatar,
  GlAlert,
} from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import GlobalSearchAutocompleteItems from '~/super_sidebar/components/global_search/components/global_search_autocomplete_items.vue';
import SearchResultHoverLayover from '~/super_sidebar/components/global_search/components/global_search_hover_overlay.vue';
import GlobalSearchNoResults from '~/super_sidebar/components/global_search/components/global_search_no_results.vue';

import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import {
  EVENT_CLICK_PROJECT_RESULT_IN_COMMAND_PALETTE,
  EVENT_CLICK_GROUP_RESULT_IN_COMMAND_PALETTE,
  EVENT_CLICK_MERGE_REQUEST_RESULT_IN_COMMAND_PALETTE,
  EVENT_CLICK_ISSUE_RESULT_IN_COMMAND_PALETTE,
  EVENT_CLICK_RECENT_ISSUE_RESULT_IN_COMMAND_PALETTE,
  EVENT_CLICK_RECENT_EPIC_RESULT_IN_COMMAND_PALETTE,
  EVENT_CLICK_RECENT_MERGE_REQUEST_RESULT_IN_COMMAND_PALETTE,
  EVENT_CLICK_USER_RESULT_IN_COMMAND_PALETTE,
} from '~/super_sidebar/components/global_search/tracking_constants';

import {
  MOCK_GROUPED_AUTOCOMPLETE_OPTIONS,
  MOCK_SCOPED_SEARCH_OPTIONS,
  MOCK_SORTED_AUTOCOMPLETE_OPTIONS,
} from '../mock_data';

Vue.use(Vuex);

describe('GlobalSearchAutocompleteItems', () => {
  let wrapper;

  const createComponent = (initialState, mockGetters, props) => {
    const store = new Vuex.Store({
      state: {
        loading: false,
        ...initialState,
      },
      getters: {
        autocompleteGroupedSearchOptions: () => MOCK_GROUPED_AUTOCOMPLETE_OPTIONS,
        scopedSearchOptions: () => MOCK_SCOPED_SEARCH_OPTIONS,
        ...mockGetters,
      },
    });

    wrapper = mount(GlobalSearchAutocompleteItems, {
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

  const findGlDisclosureDropdownGroup = () => wrapper.findComponent(GlDisclosureDropdownGroup);
  const findItems = () => wrapper.findAllComponents(GlDisclosureDropdownItem);
  const findItemTitles = () =>
    findItems().wrappers.map((w) => w.find('[data-testid="autocomplete-item-name"]').text());
  const findItemSubTitles = () =>
    findItems()
      .wrappers.map((w) => w.find('[data-testid="autocomplete-item-namespace"]'))
      .filter((w) => w.exists())
      .map((w) => w.text());
  const findItemLinks = () => findItems().wrappers.map((w) => w.find('a').attributes('href'));
  const findGlLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findAvatars = () => wrapper.findAllComponents(GlAvatar).wrappers.map((w) => w.props('src'));
  const findGlAlert = () => wrapper.findComponent(GlAlert);
  const findLayover = () => wrapper.findComponent(SearchResultHoverLayover);
  const findNoResults = () => wrapper.findComponent(GlobalSearchNoResults);

  describe('template', () => {
    const { bindInternalEventDocument } = useMockInternalEventsTracking();
    describe('when loading is true', () => {
      beforeEach(() => {
        createComponent({ loading: true });
      });

      it('renders GlLoadingIcon', () => {
        expect(findGlLoadingIcon().exists()).toBe(true);
      });

      it('does not render autocomplete options', () => {
        expect(findItems()).toHaveLength(0);
      });
    });

    describe('when api returns error', () => {
      beforeEach(() => {
        createComponent({ autocompleteError: true });
      });

      it('renders Alert', () => {
        expect(findGlAlert().exists()).toBe(true);
      });
    });

    describe('when search has no results', () => {
      beforeEach(() => {
        createComponent({ loading: false }, { autocompleteGroupedSearchOptions: () => [] });
      });

      it('renders no-results component', () => {
        expect(findNoResults().exists()).toBe(true);
      });
    });

    describe('when loading is false', () => {
      beforeEach(() => {
        createComponent();
      });

      it('does not render GlLoadingIcon', () => {
        expect(findGlLoadingIcon().exists()).toBe(false);
      });

      describe('Search results items', () => {
        it('renders item for each option in autocomplete option', () => {
          expect(findItems()).toHaveLength(MOCK_SORTED_AUTOCOMPLETE_OPTIONS.length);
        });

        it('renders titles correctly', () => {
          const expectedTitles = MOCK_SORTED_AUTOCOMPLETE_OPTIONS.map((o) => o.value || o.text);
          expect(findItemTitles()).toStrictEqual(expectedTitles);
        });

        it('renders sub-titles correctly', () => {
          const expectedSubTitles = MOCK_SORTED_AUTOCOMPLETE_OPTIONS.filter((o) => o.value).map(
            (o) => o.namespace,
          );

          expect(findItemSubTitles()).toStrictEqual(expectedSubTitles);
        });

        it('renders links correctly', () => {
          const expectedLinks = MOCK_SORTED_AUTOCOMPLETE_OPTIONS.map((o) => o.href);
          expect(findItemLinks()).toStrictEqual(expectedLinks);
        });

        it('renders avatars', () => {
          const expectedAvatars = MOCK_SORTED_AUTOCOMPLETE_OPTIONS.map((o) => o.avatar_url).filter(
            Boolean,
          );
          expect(findAvatars()).toStrictEqual(expectedAvatars);
        });

        it('does not render no-results-found component', () => {
          expect(findNoResults().exists()).toBe(false);
        });
      });

      describe.each`
        group              | text
        ${'asdfasdf'}      | ${'Go to %{kbdStart}↵%{kbdEnd}'}
        ${'Users'}         | ${'Go to profile %{kbdStart}↵%{kbdEnd}'}
        ${'Projects'}      | ${'Go to project %{kbdStart}↵%{kbdEnd}'}
        ${'Recent issues'} | ${'Go to %{kbdStart}↵%{kbdEnd}'}
        ${'Pages'}         | ${'Go to file %{kbdStart}↵%{kbdEnd}'}
      `('renders the layover text for $group', ({ group, text }) => {
        beforeEach(() => {
          createComponent(
            { loading: false },
            {
              autocompleteGroupedSearchOptions: () => [
                {
                  ...MOCK_GROUPED_AUTOCOMPLETE_OPTIONS[0],
                  name: group,
                },
              ],
            },
          );
        });

        it('renders the layover component', () => {
          expect(findLayover().exists()).toBe(true);
        });
        it('renders correct layover text', () => {
          expect(findLayover().props('textMessage')).toBe(text);
        });
      });

      describe('tracking', () => {
        it.each`
          action                     | event
          ${'Projects'}              | ${EVENT_CLICK_PROJECT_RESULT_IN_COMMAND_PALETTE}
          ${'Groups'}                | ${EVENT_CLICK_GROUP_RESULT_IN_COMMAND_PALETTE}
          ${'Merge requests'}        | ${EVENT_CLICK_MERGE_REQUEST_RESULT_IN_COMMAND_PALETTE}
          ${'Issues'}                | ${EVENT_CLICK_ISSUE_RESULT_IN_COMMAND_PALETTE}
          ${'Recent issues'}         | ${EVENT_CLICK_RECENT_ISSUE_RESULT_IN_COMMAND_PALETTE}
          ${'Recent epics'}          | ${EVENT_CLICK_RECENT_EPIC_RESULT_IN_COMMAND_PALETTE}
          ${'Recent merge requests'} | ${EVENT_CLICK_RECENT_MERGE_REQUEST_RESULT_IN_COMMAND_PALETTE}
          ${undefined}               | ${EVENT_CLICK_USER_RESULT_IN_COMMAND_PALETTE}
        `(
          "triggers tracking event '$event' after emiting action '$action'",
          ({ action, event }) => {
            const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

            findGlDisclosureDropdownGroup().vm.$emit('action', { name: action });
            expect(trackEventSpy).toHaveBeenCalledWith(event, {}, undefined);
          },
        );
      });
    });
  });
});
