import { shallowMount } from '@vue/test-utils';
import { GlFilteredSearchSuggestion } from '@gitlab/ui';
import NamespaceToken from '~/vue_shared/components/filtered_search_bar/tokens/namespace_token.vue';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';
import Api from '~/api';
import { createAlert } from '~/alert';
import { camelizeKeys } from '~/lib/utils/object_utils';

jest.mock('~/alert');
jest.mock('~/api', () => ({
  namespaces: jest.fn().mockReturnValue(new Promise(() => {})),
}));

describe('NamespaceToken', () => {
  let wrapper;

  const mockNamespaces = [
    { id: 1, full_path: 'gitlab-org', name: 'GitLab Org' },
    { id: 2, full_path: 'gitlab-com', name: 'GitLab Com' },
  ];
  const mockCamelizedNamespaces = mockNamespaces.map(camelizeKeys);

  const value = { data: 'gitlab-org' };
  const config = { type: 'namespace', symbol: '@' };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(NamespaceToken, {
      propsData: {
        value,
        config,
        active: false,
        ...props,
      },
      stubs: {
        BaseToken,
      },
    });
  };

  const findBaseToken = () => wrapper.findComponent(BaseToken);
  const findGlFilteredSearchSuggestions = () =>
    wrapper.findAllComponents(GlFilteredSearchSuggestion);

  const emitFetchSuggestions = (searchTerm) =>
    findBaseToken().vm.$emit('fetch-suggestions', searchTerm);

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    Api.namespaces.mockClear();
  });

  it('renders BaseToken with correct props', () => {
    expect(findBaseToken().props()).toMatchObject({
      config,
      value,
      active: false,
      suggestionsLoading: true,
      suggestions: [],
    });
  });

  describe('when BaseToken emits `fetch-suggestions` event', () => {
    const searchTerm = 'gitlab';

    it('shows loading state', () => {
      emitFetchSuggestions(searchTerm);

      expect(findBaseToken().props('suggestionsLoading')).toBe(true);
    });

    it('fetches namespace suggestions from the API', () => {
      emitFetchSuggestions(searchTerm);

      expect(Api.namespaces).toHaveBeenCalledWith(
        searchTerm,
        { full_path_search: true },
        expect.any(Function),
      );
    });

    describe('when Namespace API call succeeds', () => {
      beforeEach(() => {
        Api.namespaces.mockImplementation((search, options, callback) => {
          callback(mockNamespaces);
          return Promise.resolve();
        });

        emitFetchSuggestions(searchTerm);
      });

      it('renders search suggestions', () => {
        const filteredSearchSuggestions = findGlFilteredSearchSuggestions();

        expect(findBaseToken().props('suggestions')).toEqual(mockCamelizedNamespaces);
        expect(filteredSearchSuggestions).toHaveLength(mockCamelizedNamespaces.length);

        filteredSearchSuggestions.wrappers.forEach((suggestion, index) => {
          const expectedPath = mockCamelizedNamespaces[index].fullPath;
          expect(suggestion.props('value')).toBe(expectedPath);
          expect(suggestion.text()).toBe(expectedPath);
        });
      });

      it('stops loading', () => {
        expect(findBaseToken().props('suggestionsLoading')).toBe(false);
      });
    });

    describe('when Namespace API call fails', () => {
      beforeEach(() => {
        Api.namespaces.mockRejectedValue();
        emitFetchSuggestions(searchTerm);
      });

      it('creates alert', () => {
        expect(createAlert).toHaveBeenCalledWith({
          message: 'There was a problem fetching namespaces.',
        });
      });
    });
  });
});
