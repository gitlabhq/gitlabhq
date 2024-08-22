import { GlSorting } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import setWindowLocation from 'helpers/set_window_location_helper';
import * as urlUtilities from '~/lib/utils/url_utility';
import SortDropdown from '~/members/components/filter_sort/sort_dropdown.vue';
import { MEMBERS_TAB_TYPES, FIELD_KEY_MAX_ROLE } from '~/members/constants';

Vue.use(Vuex);

describe('SortDropdown', () => {
  let wrapper;

  const URL_HOST = 'https://localhost/';

  const createComponent = (state) => {
    const store = new Vuex.Store({
      modules: {
        [MEMBERS_TAB_TYPES.user]: {
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
      provide: {
        sourceId: 1,
        namespace: MEMBERS_TAB_TYPES.user,
      },
      store,
    });
  };

  const findSortingComponent = () => wrapper.findComponent(GlSorting);
  const findSortDirectionToggle = () =>
    findSortingComponent().find('button[title^="Sort direction"]');
  const findDropdownToggle = () => wrapper.find('button[aria-haspopup="listbox"]');

  beforeEach(() => {
    setWindowLocation(URL_HOST);
  });

  describe('dropdown options', () => {
    it('sets sort options', () => {
      const URL_FILTER_PARAMS = '?two_factor=enabled&search=foobar';

      setWindowLocation(URL_FILTER_PARAMS);

      const expectedSortOptions = [
        {
          text: 'Account',
          value: 'account',
        },
        {
          text: 'Access granted',
          value: 'granted',
        },
        {
          text: 'Role',
          value: 'maxRole',
        },
        {
          text: 'Last sign-in',
          value: 'lastSignIn',
        },
      ];

      createComponent();

      expect(findSortingComponent().props()).toMatchObject({
        text: expectedSortOptions[0].text,
        isAscending: true,
        sortBy: expectedSortOptions[0].value,
        sortOptions: expectedSortOptions,
      });
    });
  });

  describe('dropdown toggle', () => {
    it('defaults to sorting by "Account" in ascending order', () => {
      createComponent();

      expect(findSortingComponent().props('isAscending')).toBe(true);
      expect(findDropdownToggle().text()).toBe('Account');
    });

    it('sets text as selected sort option', () => {
      setWindowLocation('?sort=access_level_asc');

      createComponent();

      expect(findDropdownToggle().text()).toBe('Role');
    });

    describe('select new sort field', () => {
      beforeEach(async () => {
        jest.spyOn(urlUtilities, 'visitUrl').mockImplementation();
        createComponent();

        findSortingComponent().vm.$emit('sortByChange', FIELD_KEY_MAX_ROLE);
        await nextTick();
      });

      it('sorts by new field', () => {
        expect(urlUtilities.visitUrl).toHaveBeenCalledWith(`${URL_HOST}?sort=access_level_asc`);
      });
    });
  });

  describe('sort direction toggle', () => {
    beforeEach(() => {
      jest.spyOn(urlUtilities, 'visitUrl').mockImplementation();
    });

    describe('when current sort direction is ascending', () => {
      beforeEach(() => {
        setWindowLocation('?sort=access_level_asc');

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
        setWindowLocation('?sort=access_level_desc');

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
