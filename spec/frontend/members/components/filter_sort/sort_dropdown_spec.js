import { GlSorting, GlSortingItem } from '@gitlab/ui';
import { mount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import * as urlUtilities from '~/lib/utils/url_utility';
import SortDropdown from '~/members/components/filter_sort/sort_dropdown.vue';
import { MEMBER_TYPES } from '~/members/constants';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('SortDropdown', () => {
  let wrapper;

  const URL_HOST = 'https://localhost/';

  const createComponent = (state) => {
    const store = new Vuex.Store({
      modules: {
        [MEMBER_TYPES.user]: {
          namespaced: true,
          state: {
            tableSortableFields: ['account', 'granted', 'expires', 'maxRole', 'lastSignIn'],
            filteredSearchBar: {
              show: true,
              tokens: ['two_factor'],
              searchParam: 'search',
              placeholder: 'Filter members',
              recentSearchesStorageKey: 'group_members',
            },
            ...state,
          },
        },
      },
    });

    wrapper = mount(SortDropdown, {
      localVue,
      provide: {
        sourceId: 1,
        namespace: MEMBER_TYPES.user,
      },
      store,
    });
  };

  const findSortingComponent = () => wrapper.find(GlSorting);
  const findSortDirectionToggle = () =>
    findSortingComponent().find('button[title="Sort direction"]');
  const findDropdownToggle = () => wrapper.find('button[aria-haspopup="true"]');
  const findDropdownItemByText = (text) =>
    wrapper
      .findAll(GlSortingItem)
      .wrappers.find((dropdownItemWrapper) => dropdownItemWrapper.text() === text);

  describe('dropdown options', () => {
    beforeEach(() => {
      delete window.location;
      window.location = new URL(URL_HOST);
    });

    it('adds dropdown items for all the sortable fields', () => {
      const URL_FILTER_PARAMS = '?two_factor=enabled&search=foobar';
      const EXPECTED_BASE_URL = `${URL_HOST}${URL_FILTER_PARAMS}&sort=`;

      window.location.search = URL_FILTER_PARAMS;

      const expectedDropdownItems = [
        {
          label: 'Account',
          url: `${EXPECTED_BASE_URL}name_asc`,
        },
        {
          label: 'Access granted',
          url: `${EXPECTED_BASE_URL}last_joined`,
        },
        {
          label: 'Max role',
          url: `${EXPECTED_BASE_URL}access_level_asc`,
        },
        {
          label: 'Last sign-in',
          url: `${EXPECTED_BASE_URL}recent_sign_in`,
        },
      ];

      createComponent();

      expectedDropdownItems.forEach((expectedDropdownItem) => {
        const dropdownItem = findDropdownItemByText(expectedDropdownItem.label);

        expect(dropdownItem).not.toBe(null);
        expect(dropdownItem.find('a').attributes('href')).toBe(expectedDropdownItem.url);
      });
    });

    it('checks selected sort option', () => {
      window.location.search = '?sort=access_level_asc';

      createComponent();

      expect(findDropdownItemByText('Max role').vm.$attrs.active).toBe(true);
    });
  });

  describe('dropdown toggle', () => {
    beforeEach(() => {
      delete window.location;
      window.location = new URL(URL_HOST);
    });

    it('defaults to sorting by "Account" in ascending order', () => {
      createComponent();

      expect(findSortingComponent().props('isAscending')).toBe(true);
      expect(findDropdownToggle().text()).toBe('Account');
    });

    it('sets text as selected sort option', () => {
      window.location.search = '?sort=access_level_asc';

      createComponent();

      expect(findDropdownToggle().text()).toBe('Max role');
    });
  });

  describe('sort direction toggle', () => {
    beforeEach(() => {
      delete window.location;
      window.location = new URL(URL_HOST);

      jest.spyOn(urlUtilities, 'visitUrl');
    });

    describe('when current sort direction is ascending', () => {
      beforeEach(() => {
        window.location.search = '?sort=access_level_asc';

        createComponent();
      });

      describe('when sort direction toggle is clicked', () => {
        beforeEach(() => {
          findSortDirectionToggle().trigger('click');
        });

        it('sorts in descending order', () => {
          expect(urlUtilities.visitUrl).toHaveBeenCalledWith(`${URL_HOST}?sort=access_level_desc`);
        });
      });
    });

    describe('when current sort direction is descending', () => {
      beforeEach(() => {
        window.location.search = '?sort=access_level_desc';

        createComponent();
      });

      describe('when sort direction toggle is clicked', () => {
        beforeEach(() => {
          findSortDirectionToggle().trigger('click');
        });

        it('sorts in ascending order', () => {
          expect(urlUtilities.visitUrl).toHaveBeenCalledWith(`${URL_HOST}?sort=access_level_asc`);
        });
      });
    });
  });
});
