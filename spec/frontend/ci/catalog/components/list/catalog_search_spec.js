import { GlFilteredSearch, GlSorting } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CatalogSearch from '~/ci/catalog/components/list/catalog_search.vue';
import TopicToken from '~/ci/catalog/components/tokens/topic_token.vue';
import VerificationLevelToken from '~/ci/catalog/components/tokens/verification_level_token.vue';
import {
  SORT_ASC,
  SORT_DESC,
  SORT_OPTION_CREATED,
  SORT_OPTION_POPULARITY,
  SORT_OPTION_STAR_COUNT,
} from '~/ci/catalog/constants';

describe('CatalogSearch', () => {
  let wrapper;

  const findFilteredSearch = () => wrapper.findComponent(GlFilteredSearch);
  const findSorting = () => wrapper.findComponent(GlSorting);
  const findAllSortingItems = () => findSorting().props('sortOptions');

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(CatalogSearch, {
      propsData: props,
    });
  };

  describe('default UI', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the filtered search', () => {
      expect(findFilteredSearch().exists()).toBe(true);
    });

    it('configures the verification level token', () => {
      const tokens = findFilteredSearch().props('availableTokens');
      const verificationToken = tokens.find((t) => t.type === 'verificationLevel');

      expect(verificationToken).toMatchObject({
        type: 'verificationLevel',
        token: VerificationLevelToken,
        unique: true,
      });
    });

    it('configures the topic token', () => {
      const tokens = findFilteredSearch().props('availableTokens');
      const topicToken = tokens.find((t) => t.type === 'topic');

      expect(topicToken).toMatchObject({
        type: 'topic',
        token: TopicToken,
        unique: true,
        multiSelect: true,
      });
    });

    it('adds sorting options', () => {
      const sortOptionsProp = findAllSortingItems();
      expect(sortOptionsProp).toHaveLength(4);
      expect(sortOptionsProp[0].text).toBe('Popularity');
    });

    it('renders the `Popularity` option as the default', () => {
      expect(findSorting().props('text')).toBe('Popularity');
    });
  });

  describe('filtered search value', () => {
    it('sets an empty value by default', () => {
      createComponent();

      expect(findFilteredSearch().props('value')).toEqual([]);
    });

    it('includes the initial search term', () => {
      createComponent({ initialSearchTerm: 'test' });

      expect(findFilteredSearch().props('value')).toEqual(['test']);
    });

    it('includes the initial verification level', () => {
      createComponent({ initialVerificationLevel: 'GITLAB_MAINTAINED' });

      expect(findFilteredSearch().props('value')).toEqual([
        {
          type: 'verificationLevel',
          value: { data: 'GITLAB_MAINTAINED', operator: '=' },
        },
      ]);
    });

    it('includes initial topics', () => {
      createComponent({ initialTopics: ['ruby', 'ci-cd'] });

      expect(findFilteredSearch().props('value')).toEqual([
        {
          type: 'topic',
          value: { data: ['ruby', 'ci-cd'], operator: '||' },
        },
      ]);
    });

    it('includes all filters together', () => {
      createComponent({
        initialSearchTerm: 'test',
        initialVerificationLevel: 'GITLAB_MAINTAINED',
        initialTopics: ['ruby'],
      });

      expect(findFilteredSearch().props('value')).toEqual([
        {
          type: 'verificationLevel',
          value: { data: 'GITLAB_MAINTAINED', operator: '=' },
        },
        {
          type: 'topic',
          value: { data: ['ruby'], operator: '||' },
        },
        'test',
      ]);
    });
  });

  describe('search and filter', () => {
    beforeEach(() => {
      createComponent();
    });

    it.each`
      description                                       | filters                                                                                                                                               | expected
      ${'with search term on submit'}                   | ${['dog']}                                                                                                                                            | ${{ searchTerm: 'dog', verificationLevel: null, topics: [] }}
      ${'with empty search term when cleared'}          | ${[]}                                                                                                                                                 | ${{ searchTerm: null, verificationLevel: null, topics: [] }}
      ${'with verification level'}                      | ${[{ type: 'verificationLevel', value: { data: 'GITLAB_MAINTAINED', operator: '=' } }]}                                                               | ${{ searchTerm: null, verificationLevel: 'GITLAB_MAINTAINED', topics: [] }}
      ${'with both search term and verification level'} | ${['cat', { type: 'verificationLevel', value: { data: 'UNVERIFIED', operator: '=' } }]}                                                               | ${{ searchTerm: 'cat', verificationLevel: 'UNVERIFIED', topics: [] }}
      ${'with single topic'}                            | ${[{ type: 'topic', value: { data: 'ruby', operator: '||' } }]}                                                                                       | ${{ searchTerm: null, verificationLevel: null, topics: ['ruby'] }}
      ${'with multiple topics'}                         | ${[{ type: 'topic', value: { data: ['ruby', 'ci-cd'], operator: '||' } }]}                                                                            | ${{ searchTerm: null, verificationLevel: null, topics: ['ruby', 'ci-cd'] }}
      ${'with all filters'}                             | ${['cat', { type: 'verificationLevel', value: { data: 'UNVERIFIED', operator: '=' } }, { type: 'topic', value: { data: ['ruby'], operator: '||' } }]} | ${{ searchTerm: 'cat', verificationLevel: 'UNVERIFIED', topics: ['ruby'] }}
    `('emits update-filters $description', ({ filters, expected }) => {
      findFilteredSearch().vm.$emit('submit', filters);

      expect(wrapper.emitted('update-filters')).toEqual([[expected]]);
    });
  });

  describe('sort', () => {
    beforeEach(() => {
      createComponent();
    });

    describe('when changing sort order', () => {
      it('changes the `isAscending` prop to the sorting component', async () => {
        expect(findSorting().props().isAscending).toBe(false);

        await findSorting().vm.$emit('sortDirectionChange');

        expect(findSorting().props().isAscending).toBe(true);

        await findSorting().vm.$emit('sortDirectionChange');

        expect(findSorting().props().isAscending).toBe(false);
      });

      it('emits an `update-sorting` event with the new direction', async () => {
        expect(wrapper.emitted('update-sorting')).toBeUndefined();

        await findSorting().vm.$emit('sortDirectionChange');
        await findSorting().vm.$emit('sortDirectionChange');

        expect(wrapper.emitted('update-sorting')).toEqual([
          [`${SORT_OPTION_POPULARITY}_${SORT_ASC}`],
          [`${SORT_OPTION_POPULARITY}_${SORT_DESC}`],
        ]);
      });
    });

    describe('when changing sort option', () => {
      it('changes the sort option to `Created date`', async () => {
        await findSorting().vm.$emit('sortByChange', SORT_OPTION_CREATED);

        expect(findSorting().props().sortBy).toBe(SORT_OPTION_CREATED);
        expect(findSorting().props().text).toBe('Created date');
      });

      it('changes the sort option to `Star count`', async () => {
        await findSorting().vm.$emit('sortByChange', SORT_OPTION_STAR_COUNT);

        expect(findSorting().props('sortBy')).toBe(SORT_OPTION_STAR_COUNT);
        expect(findSorting().props('text')).toBe('Star count');
      });
    });
  });
});
