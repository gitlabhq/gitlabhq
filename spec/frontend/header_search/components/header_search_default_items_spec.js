import { GlDropdownItem, GlDropdownSectionHeader } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import HeaderSearchDefaultItems from '~/header_search/components/header_search_default_items.vue';
import { MOCK_SEARCH_CONTEXT, MOCK_DEFAULT_SEARCH_OPTIONS } from '../mock_data';

Vue.use(Vuex);

describe('HeaderSearchDefaultItems', () => {
  let wrapper;

  const createComponent = (initialState, props) => {
    const store = new Vuex.Store({
      state: {
        searchContext: MOCK_SEARCH_CONTEXT,
        ...initialState,
      },
      getters: {
        defaultSearchOptions: () => MOCK_DEFAULT_SEARCH_OPTIONS,
      },
    });

    wrapper = shallowMount(HeaderSearchDefaultItems, {
      store,
      propsData: {
        ...props,
      },
    });
  };

  const findDropdownHeader = () => wrapper.findComponent(GlDropdownSectionHeader);
  const findDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findFirstDropdownItem = () => findDropdownItems().at(0);
  const findDropdownItemTitles = () => findDropdownItems().wrappers.map((w) => w.text());
  const findDropdownItemLinks = () => findDropdownItems().wrappers.map((w) => w.attributes('href'));

  describe('template', () => {
    describe('Dropdown items', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders item for each option in defaultSearchOptions', () => {
        expect(findDropdownItems()).toHaveLength(MOCK_DEFAULT_SEARCH_OPTIONS.length);
      });

      it('renders titles correctly', () => {
        const expectedTitles = MOCK_DEFAULT_SEARCH_OPTIONS.map((o) => o.title);
        expect(findDropdownItemTitles()).toStrictEqual(expectedTitles);
      });

      it('renders links correctly', () => {
        const expectedLinks = MOCK_DEFAULT_SEARCH_OPTIONS.map((o) => o.url);
        expect(findDropdownItemLinks()).toStrictEqual(expectedLinks);
      });
    });

    describe.each`
      group                     | project                     | dropdownTitle
      ${null}                   | ${null}                     | ${'All GitLab'}
      ${{ name: 'Test Group' }} | ${null}                     | ${'Test Group'}
      ${{ name: 'Test Group' }} | ${{ name: 'Test Project' }} | ${'Test Project'}
    `('Dropdown Header', ({ group, project, dropdownTitle }) => {
      describe(`when group is ${group?.name} and project is ${project?.name}`, () => {
        beforeEach(() => {
          createComponent({
            searchContext: {
              group,
              project,
            },
          });
        });

        it(`should render as ${dropdownTitle}`, () => {
          expect(findDropdownHeader().text()).toBe(dropdownTitle);
        });
      });
    });

    describe.each`
      currentFocusedOption              | isFocused | ariaSelected
      ${null}                           | ${false}  | ${undefined}
      ${{ html_id: 'not-a-match' }}     | ${false}  | ${undefined}
      ${MOCK_DEFAULT_SEARCH_OPTIONS[0]} | ${true}   | ${'true'}
    `('isOptionFocused', ({ currentFocusedOption, isFocused, ariaSelected }) => {
      describe(`when currentFocusedOption.html_id is ${currentFocusedOption?.html_id}`, () => {
        beforeEach(() => {
          createComponent({}, { currentFocusedOption });
        });

        it(`should${isFocused ? '' : ' not'} have gl-bg-gray-50 applied`, () => {
          expect(findFirstDropdownItem().classes('gl-bg-gray-50')).toBe(isFocused);
        });

        it(`sets "aria-selected to ${ariaSelected}`, () => {
          expect(findFirstDropdownItem().attributes('aria-selected')).toBe(ariaSelected);
        });
      });
    });
  });
});
