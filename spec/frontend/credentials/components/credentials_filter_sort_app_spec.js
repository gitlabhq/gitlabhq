import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { GlFilteredSearch, GlSorting } from '@gitlab/ui';
import CredentialsFilterSortApp from '~/credentials/components/credentials_filter_sort_app.vue';
import { visitUrl, getBaseURL } from '~/lib/utils/url_utility';
import setWindowLocation from 'helpers/set_window_location_helper';
import { SORT_KEY_NAME } from '~/credentials/constants';

const mockFilters = [
  'dummy',
  {
    type: 'created',
    value: { data: '2025-01-01', operator: '<' },
    id: 1,
  },
  {
    type: 'expires',
    value: { data: '2025-01-01', operator: '<' },
    id: 3,
  },
  {
    type: 'last_used',
    value: { data: '2025-01-01', operator: '≥' },
    id: 2,
  },
  {
    type: 'state',
    value: { data: 'inactive', operator: '=' },
    id: 3,
  },
];

jest.mock('~/lib/utils/url_utility', () => {
  return {
    ...jest.requireActual('~/lib/utils/url_utility'),
    visitUrl: jest.fn(),
  };
});

describe('CredentialsFilterSortApp', () => {
  let wrapper;
  const URL_HOST = 'https://localhost/';

  const createComponent = () => {
    wrapper = mount(CredentialsFilterSortApp, {
      stubs: {
        GlFilteredSearch: true,
      },
    });
  };

  beforeEach(() => {
    setWindowLocation(URL_HOST);
  });

  const findFilteredSearch = () => wrapper.findComponent(GlFilteredSearch);
  const findAvailableTokens = () => findFilteredSearch().props('availableTokens');
  const findSortingComponent = () => wrapper.findComponent(GlSorting);
  const findSortDirectionToggle = () =>
    findSortingComponent().find('button[title^="Sort direction"]');
  const findDropdownToggle = () => findSortingComponent().find('button[aria-haspopup="listbox"]');

  describe('Mounts GlFilteredSearch with corresponding filters', () => {
    it.each`
      option
      ${'personal_access_tokens'}
      ${'ssh_keys'}
      ${'resource_access_tokens'}
      ${'gpg_keys'}
      ${'active'}
      ${'inactive'}
      ${'true'}
    `(`includes token with option $option`, ({ option }) => {
      createComponent();
      const tokenExists = findAvailableTokens().find((token) => {
        return token.options?.find(({ value }) => {
          return value === option;
        });
      });

      expect(Boolean(tokenExists)).toBe(true);
    });

    it.each`
      filter
      ${'ssh_keys'}
      ${'gpg_keys'}
    `(`exclude all other tokens if filter is $filter`, async ({ filter }) => {
      createComponent();
      findFilteredSearch().vm.$emit('input', [
        {
          type: 'filter',
          value: { data: filter, operator: '=' },
          id: 1,
        },
      ]);
      await nextTick();

      const tokens = findAvailableTokens();
      expect(tokens.length).toEqual(1);
      expect(tokens[0].type).toBe('filter');
    });
  });

  describe('URL search params', () => {
    afterEach(() => {
      window.history.pushState({}, null, '');
    });

    it.each`
      filter
      ${'ssh_keys'}
      ${'gpg_keys'}
    `(`exclude all other tokens if filter is $filter`, ({ filter }) => {
      window.history.replaceState({}, '', `/?filter=${filter}`);
      createComponent();

      const tokens = findAvailableTokens();
      expect(tokens.length).toEqual(1);
      expect(tokens[0].type).toBe('filter');
    });

    it('triggers location changes having emitted `submit` event', async () => {
      createComponent();
      const filteredSearch = findFilteredSearch();
      filteredSearch.vm.$emit('submit', mockFilters);
      await nextTick();
      expect(visitUrl).toHaveBeenCalledWith(
        `${getBaseURL()}/?search=dummy&created_before=2025-01-01&expires_before=2025-01-01&last_used_after=2025-01-01&state=inactive`,
      );
    });

    it('Removes all query param except filter if filter has been changed', async () => {
      window.history.replaceState({}, '', '/?page=2&non-existing-token=dummy');
      createComponent();
      const filteredSearch = findFilteredSearch();
      filteredSearch.vm.$emit('submit', mockFilters);
      await nextTick();
      expect(visitUrl).toHaveBeenCalledWith(
        `${getBaseURL()}/?search=dummy&created_before=2025-01-01&expires_before=2025-01-01&last_used_after=2025-01-01&state=inactive`,
      );
    });
  });
  describe('renders CredentialsSortApp component', () => {
    it('when url has filter param with value personal_access_tokens', async () => {
      setWindowLocation('?filter=personal_access_tokens');
      createComponent();
      await nextTick();

      expect(findSortingComponent().exists()).toBe(true);
    });
    it('when url has no filter param', async () => {
      createComponent();
      await nextTick();

      expect(findSortingComponent().exists()).toBe(true);
    });
  });

  describe('sort dropdown', () => {
    it('defaults to sorting by "Created date" in ascending order', async () => {
      createComponent();
      await nextTick();
      expect(findSortingComponent().props('isAscending')).toBe(true);
      expect(findDropdownToggle().text()).toBe('Expiration date');
    });

    it('sets the sort label correctly', () => {
      setWindowLocation('?sort=name_asc');

      createComponent();

      expect(findDropdownToggle().text()).toBe('Name');
    });

    describe('new sort option is selected', () => {
      beforeEach(async () => {
        visitUrl.mockImplementation(() => {});
        createComponent();

        findSortingComponent().vm.$emit('sortByChange', SORT_KEY_NAME);
        await nextTick();
      });

      it('sorts by new option', () => {
        expect(visitUrl).toHaveBeenCalledWith(`${URL_HOST}?sort=name_asc`);
      });
    });
  });

  describe('sort direction toggle', () => {
    beforeEach(() => {
      visitUrl.mockImplementation(() => {});
    });

    describe('when current sort direction is ascending', () => {
      beforeEach(() => {
        setWindowLocation('?sort=name_asc');

        createComponent();
      });

      describe('when sort direction toggle is clicked', () => {
        beforeEach(() => {
          findSortDirectionToggle().trigger('click');
        });

        it('sorts in descending order', () => {
          expect(visitUrl).toHaveBeenCalledWith(`${URL_HOST}?sort=name_desc`);
        });
      });
    });

    describe('when current sort direction is descending', () => {
      beforeEach(() => {
        setWindowLocation('?sort=name_desc');

        createComponent();
      });

      describe('when sort direction toggle is clicked', () => {
        beforeEach(() => {
          findSortDirectionToggle().trigger('click');
        });

        it('sorts in ascending order', () => {
          expect(visitUrl).toHaveBeenCalledWith(`${URL_HOST}?sort=name_asc`);
        });
      });
    });
  });
});
