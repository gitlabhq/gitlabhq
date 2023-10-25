import { shallowMount } from '@vue/test-utils';
import setWindowLocation from 'helpers/set_window_location_helper';
import * as urlHelpers from '~/lib/utils/url_utility';
import SearchBar from '~/ml/model_registry/components/search_bar.vue';
import { BASE_SORT_FIELDS } from '~/ml/model_registry/constants';
import RegistrySearch from '~/vue_shared/components/registry/registry_search.vue';

let wrapper;

const makeUrl = ({ filter = 'query', orderBy = 'name', sort = 'asc' } = {}) =>
  `https://blah.com/?name=${filter}&orderBy=${orderBy}&sort=${sort}`;

const createWrapper = () => {
  wrapper = shallowMount(SearchBar, { propsData: { sortableFields: BASE_SORT_FIELDS } });
};

const findRegistrySearch = () => wrapper.findComponent(RegistrySearch);

describe('SearchBar', () => {
  beforeEach(() => {
    createWrapper();
  });

  it('passes default filter and sort by to registry search', () => {
    expect(findRegistrySearch().props()).toMatchObject({
      filters: [],
      sorting: {
        orderBy: 'created_at',
        sort: 'desc',
      },
      sortableFields: BASE_SORT_FIELDS,
    });
  });

  it('sets the component filters based on the querystring', () => {
    const filter = 'A';
    setWindowLocation(makeUrl({ filter }));

    createWrapper();

    expect(findRegistrySearch().props('filters')).toMatchObject([{ value: { data: filter } }]);
  });

  it('sets the registry search sort based on the querystring', () => {
    const orderBy = 'B';
    const sort = 'C';

    setWindowLocation(makeUrl({ orderBy, sort }));

    createWrapper();

    expect(findRegistrySearch().props('sorting')).toMatchObject({ orderBy, sort: 'c' });
  });

  describe('Search submit', () => {
    beforeEach(() => {
      setWindowLocation(makeUrl());
      jest.spyOn(urlHelpers, 'visitUrl').mockImplementation(() => {});

      createWrapper();
    });

    it('On submit, resets the cursor and reloads to correct page', () => {
      findRegistrySearch().vm.$emit('filter:submit');

      expect(urlHelpers.visitUrl).toHaveBeenCalledTimes(1);
      expect(urlHelpers.visitUrl).toHaveBeenCalledWith(makeUrl());
    });

    it('On sorting changed, resets cursor and reloads to correct page', () => {
      const orderBy = 'created_at';
      findRegistrySearch().vm.$emit('sorting:changed', { orderBy });

      expect(urlHelpers.visitUrl).toHaveBeenCalledTimes(1);
      expect(urlHelpers.visitUrl).toHaveBeenCalledWith(makeUrl({ orderBy }));
    });

    it('On direction changed, reloads to correct page', () => {
      const sort = 'asc';
      findRegistrySearch().vm.$emit('sorting:changed', { sort });

      expect(urlHelpers.visitUrl).toHaveBeenCalledTimes(1);
      expect(urlHelpers.visitUrl).toHaveBeenCalledWith(makeUrl({ sort }));
    });
  });
});
