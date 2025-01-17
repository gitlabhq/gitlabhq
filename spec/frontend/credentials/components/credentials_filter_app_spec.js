import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { GlFilteredSearch } from '@gitlab/ui';
import CredentialsFilterApp from '~/credentials/components/credentials_filter_app.vue';
import { visitUrl, getBaseURL } from '~/lib/utils/url_utility';

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

describe('CredentialsFilterApp', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(CredentialsFilterApp);
  };

  const findFilteredSearch = () => wrapper.findComponent(GlFilteredSearch);
  const findAvailableTokens = () => findFilteredSearch().props('availableTokens');

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
});
