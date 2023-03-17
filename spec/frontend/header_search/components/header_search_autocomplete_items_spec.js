import { GlDropdownItem, GlLoadingIcon, GlAvatar, GlAlert, GlDropdownDivider } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import HeaderSearchAutocompleteItems from '~/header_search/components/header_search_autocomplete_items.vue';
import { LARGE_AVATAR_PX, SMALL_AVATAR_PX } from '~/header_search/constants';
import {
  PROJECTS_CATEGORY,
  GROUPS_CATEGORY,
  ISSUES_CATEGORY,
  MERGE_REQUEST_CATEGORY,
  RECENT_EPICS_CATEGORY,
} from '~/vue_shared/global_search/constants';
import {
  MOCK_GROUPED_AUTOCOMPLETE_OPTIONS,
  MOCK_SORTED_AUTOCOMPLETE_OPTIONS,
  MOCK_GROUPED_AUTOCOMPLETE_OPTIONS_SETTINGS_HELP,
  MOCK_GROUPED_AUTOCOMPLETE_OPTIONS_HELP,
  MOCK_SEARCH,
  MOCK_GROUPED_AUTOCOMPLETE_OPTIONS_2,
} from '../mock_data';

Vue.use(Vuex);

describe('HeaderSearchAutocompleteItems', () => {
  let wrapper;

  const createComponent = (initialState, mockGetters, props) => {
    const store = new Vuex.Store({
      state: {
        loading: false,
        ...initialState,
      },
      getters: {
        autocompleteGroupedSearchOptions: () => MOCK_GROUPED_AUTOCOMPLETE_OPTIONS,
        ...mockGetters,
      },
    });

    wrapper = shallowMount(HeaderSearchAutocompleteItems, {
      store,
      propsData: {
        ...props,
      },
    });
  };

  const findDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findGlDropdownDividers = () => wrapper.findAllComponents(GlDropdownDivider);
  const findFirstDropdownItem = () => findDropdownItems().at(0);
  const findDropdownItemTitles = () =>
    findDropdownItems().wrappers.map((w) => w.findAll('span').at(1).text());
  const findDropdownItemSubTitles = () =>
    findDropdownItems()
      .wrappers.filter((w) => w.findAll('span').length > 2)
      .map((w) => w.findAll('span').at(2).text());
  const findDropdownItemLinks = () => findDropdownItems().wrappers.map((w) => w.attributes('href'));
  const findGlLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findGlAvatar = () => wrapper.findComponent(GlAvatar);
  const findGlAlert = () => wrapper.findComponent(GlAlert);

  describe('template', () => {
    describe('when loading is true', () => {
      beforeEach(() => {
        createComponent({ loading: true });
      });

      it('renders GlLoadingIcon', () => {
        expect(findGlLoadingIcon().exists()).toBe(true);
      });

      it('does not render autocomplete options', () => {
        expect(findDropdownItems()).toHaveLength(0);
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
    describe('when loading is false', () => {
      beforeEach(() => {
        createComponent({ loading: false });
      });

      it('does not render GlLoadingIcon', () => {
        expect(findGlLoadingIcon().exists()).toBe(false);
      });

      describe('Dropdown items', () => {
        it('renders item for each option in autocomplete option', () => {
          expect(findDropdownItems()).toHaveLength(MOCK_SORTED_AUTOCOMPLETE_OPTIONS.length);
        });

        it('renders titles correctly', () => {
          const expectedTitles = MOCK_SORTED_AUTOCOMPLETE_OPTIONS.map((o) => o.value || o.label);
          expect(findDropdownItemTitles()).toStrictEqual(expectedTitles);
        });

        it('renders sub-titles correctly', () => {
          const expectedSubTitles = MOCK_SORTED_AUTOCOMPLETE_OPTIONS.filter((o) => o.value).map(
            (o) => o.label,
          );
          expect(findDropdownItemSubTitles()).toStrictEqual(expectedSubTitles);
        });

        it('renders links correctly', () => {
          const expectedLinks = MOCK_SORTED_AUTOCOMPLETE_OPTIONS.map((o) => o.url);
          expect(findDropdownItemLinks()).toStrictEqual(expectedLinks);
        });
      });

      describe.each`
        item                                                                                                          | showAvatar | avatarSize                 | searchContext                            | entityId | entityName
        ${{ data: [{ category: PROJECTS_CATEGORY, avatar_url: null }] }}                                              | ${true}    | ${String(LARGE_AVATAR_PX)} | ${{ project: { id: 29 } }}               | ${'29'}  | ${''}
        ${{ data: [{ category: GROUPS_CATEGORY, avatar_url: '/123' }] }}                                              | ${true}    | ${String(LARGE_AVATAR_PX)} | ${{ group: { id: 12 } }}                 | ${'12'}  | ${''}
        ${{ data: [{ category: 'Help', avatar_url: '' }] }}                                                           | ${true}    | ${String(SMALL_AVATAR_PX)} | ${null}                                  | ${'0'}   | ${''}
        ${{ data: [{ category: 'Settings' }] }}                                                                       | ${false}   | ${false}                   | ${null}                                  | ${false} | ${false}
        ${{ data: [{ category: GROUPS_CATEGORY, avatar_url: null }] }}                                                | ${true}    | ${String(LARGE_AVATAR_PX)} | ${{ group: { id: 1, name: 'test1' } }}   | ${'1'}   | ${'test1'}
        ${{ data: [{ category: PROJECTS_CATEGORY, avatar_url: null }] }}                                              | ${true}    | ${String(LARGE_AVATAR_PX)} | ${{ project: { id: 2, name: 'test2' } }} | ${'2'}   | ${'test2'}
        ${{ data: [{ category: ISSUES_CATEGORY, avatar_url: null }] }}                                                | ${true}    | ${String(SMALL_AVATAR_PX)} | ${{ project: { id: 3, name: 'test3' } }} | ${'3'}   | ${'test3'}
        ${{ data: [{ category: MERGE_REQUEST_CATEGORY, avatar_url: null }] }}                                         | ${true}    | ${String(SMALL_AVATAR_PX)} | ${{ project: { id: 4, name: 'test4' } }} | ${'4'}   | ${'test4'}
        ${{ data: [{ category: RECENT_EPICS_CATEGORY, avatar_url: null }] }}                                          | ${true}    | ${String(SMALL_AVATAR_PX)} | ${{ group: { id: 5, name: 'test5' } }}   | ${'5'}   | ${'test5'}
        ${{ data: [{ category: GROUPS_CATEGORY, avatar_url: null, group_id: 6, group_name: 'test6' }] }}              | ${true}    | ${String(LARGE_AVATAR_PX)} | ${null}                                  | ${'6'}   | ${'test6'}
        ${{ data: [{ category: PROJECTS_CATEGORY, avatar_url: null, project_id: 7, project_name: 'test7' }] }}        | ${true}    | ${String(LARGE_AVATAR_PX)} | ${null}                                  | ${'7'}   | ${'test7'}
        ${{ data: [{ category: ISSUES_CATEGORY, avatar_url: null, project_id: 8, project_name: 'test8' }] }}          | ${true}    | ${String(SMALL_AVATAR_PX)} | ${null}                                  | ${'8'}   | ${'test8'}
        ${{ data: [{ category: MERGE_REQUEST_CATEGORY, avatar_url: null, project_id: 9, project_name: 'test9' }] }}   | ${true}    | ${String(SMALL_AVATAR_PX)} | ${null}                                  | ${'9'}   | ${'test9'}
        ${{ data: [{ category: RECENT_EPICS_CATEGORY, avatar_url: null, group_id: 10, group_name: 'test10' }] }}      | ${true}    | ${String(SMALL_AVATAR_PX)} | ${null}                                  | ${'10'}  | ${'test10'}
        ${{ data: [{ category: GROUPS_CATEGORY, avatar_url: null, group_id: 11, group_name: 'test11' }] }}            | ${true}    | ${String(LARGE_AVATAR_PX)} | ${{ group: { id: 1, name: 'test1' } }}   | ${'11'}  | ${'test11'}
        ${{ data: [{ category: PROJECTS_CATEGORY, avatar_url: null, project_id: 12, project_name: 'test12' }] }}      | ${true}    | ${String(LARGE_AVATAR_PX)} | ${{ project: { id: 2, name: 'test2' } }} | ${'12'}  | ${'test12'}
        ${{ data: [{ category: ISSUES_CATEGORY, avatar_url: null, project_id: 13, project_name: 'test13' }] }}        | ${true}    | ${String(SMALL_AVATAR_PX)} | ${{ project: { id: 3, name: 'test3' } }} | ${'13'}  | ${'test13'}
        ${{ data: [{ category: MERGE_REQUEST_CATEGORY, avatar_url: null, project_id: 14, project_name: 'test14' }] }} | ${true}    | ${String(SMALL_AVATAR_PX)} | ${{ project: { id: 4, name: 'test4' } }} | ${'14'}  | ${'test14'}
        ${{ data: [{ category: RECENT_EPICS_CATEGORY, avatar_url: null, group_id: 15, group_name: 'test15' }] }}      | ${true}    | ${String(SMALL_AVATAR_PX)} | ${{ group: { id: 5, name: 'test5' } }}   | ${'15'}  | ${'test15'}
      `('GlAvatar', ({ item, showAvatar, avatarSize, searchContext, entityId, entityName }) => {
        describe(`when category is ${item.data[0].category} and avatar_url is ${item.data[0].avatar_url}`, () => {
          beforeEach(() => {
            createComponent({ searchContext }, { autocompleteGroupedSearchOptions: () => [item] });
          });

          it(`should${showAvatar ? '' : ' not'} render`, () => {
            expect(findGlAvatar().exists()).toBe(showAvatar);
          });

          it(`should set avatarSize to ${avatarSize}`, () => {
            expect(findGlAvatar().exists() && findGlAvatar().attributes('size')).toBe(avatarSize);
          });

          it(`should set avatar entityId to ${entityId}`, () => {
            expect(findGlAvatar().exists() && findGlAvatar().attributes('entityid')).toBe(entityId);
          });

          it(`should set avatar entityName to ${entityName}`, () => {
            expect(findGlAvatar().exists() && findGlAvatar().attributes('entityname')).toBe(
              entityName,
            );
          });
        });
      });
    });

    describe.each`
      currentFocusedOption                   | isFocused | ariaSelected
      ${null}                                | ${false}  | ${undefined}
      ${{ html_id: 'not-a-match' }}          | ${false}  | ${undefined}
      ${MOCK_SORTED_AUTOCOMPLETE_OPTIONS[0]} | ${true}   | ${'true'}
    `('isOptionFocused', ({ currentFocusedOption, isFocused, ariaSelected }) => {
      describe(`when currentFocusedOption.html_id is ${currentFocusedOption?.html_id}`, () => {
        beforeEach(() => {
          createComponent({}, {}, { currentFocusedOption });
        });

        it(`should${isFocused ? '' : ' not'} have gl-bg-gray-50 applied`, () => {
          expect(findFirstDropdownItem().classes('gl-bg-gray-50')).toBe(isFocused);
        });

        it(`sets "aria-selected to ${ariaSelected}`, () => {
          expect(findFirstDropdownItem().attributes('aria-selected')).toBe(ariaSelected);
        });
      });
    });

    describe.each`
      search         | items                                              | dividerCount
      ${null}        | ${[]}                                              | ${0}
      ${''}          | ${[]}                                              | ${0}
      ${'1'}         | ${[]}                                              | ${0}
      ${')'}         | ${[]}                                              | ${0}
      ${'t'}         | ${MOCK_GROUPED_AUTOCOMPLETE_OPTIONS_SETTINGS_HELP} | ${1}
      ${'te'}        | ${MOCK_GROUPED_AUTOCOMPLETE_OPTIONS_HELP}          | ${0}
      ${'tes'}       | ${MOCK_GROUPED_AUTOCOMPLETE_OPTIONS_2}             | ${1}
      ${MOCK_SEARCH} | ${MOCK_GROUPED_AUTOCOMPLETE_OPTIONS_2}             | ${1}
    `('Header Search Dropdown Dividers', ({ search, items, dividerCount }) => {
      describe(`when search is ${search}`, () => {
        beforeEach(() => {
          createComponent(
            { search },
            {
              autocompleteGroupedSearchOptions: () => items,
            },
            {},
          );
        });

        it(`component should have ${dividerCount} dividers`, () => {
          expect(findGlDropdownDividers()).toHaveLength(dividerCount);
        });
      });
    });
  });

  describe('watchers', () => {
    describe('currentFocusedOption', () => {
      beforeEach(() => {
        createComponent();
      });

      it('when focused changes to existing element calls scroll into view on the newly focused element', async () => {
        const focusedElement = findFirstDropdownItem().element;
        const scrollSpy = jest.spyOn(focusedElement, 'scrollIntoView');

        wrapper.setProps({ currentFocusedOption: MOCK_SORTED_AUTOCOMPLETE_OPTIONS[0] });

        await nextTick();

        expect(scrollSpy).toHaveBeenCalledWith(false);
        scrollSpy.mockRestore();
      });
    });
  });
});
