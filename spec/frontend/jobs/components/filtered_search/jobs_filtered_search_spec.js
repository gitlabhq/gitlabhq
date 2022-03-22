import { GlFilteredSearch } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { OPERATOR_IS_ONLY } from '~/vue_shared/components/filtered_search_bar/constants';
import JobsFilteredSearch from '~/jobs/components/filtered_search/jobs_filtered_search.vue';
import { mockFailedSearchToken } from '../../mock_data';

describe('Jobs filtered search', () => {
  let wrapper;

  const findFilteredSearch = () => wrapper.findComponent(GlFilteredSearch);
  const getSearchToken = (type) =>
    findFilteredSearch()
      .props('availableTokens')
      .find((token) => token.type === type);

  const findStatusToken = () => getSearchToken('status');

  const createComponent = () => {
    wrapper = shallowMount(JobsFilteredSearch);
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('displays filtered search', () => {
    expect(findFilteredSearch().exists()).toBe(true);
  });

  it('displays status token', () => {
    expect(findStatusToken()).toMatchObject({
      type: 'status',
      icon: 'status',
      title: 'Status',
      unique: true,
      operators: OPERATOR_IS_ONLY,
    });
  });

  it('emits filter token to parent component', () => {
    findFilteredSearch().vm.$emit('submit', mockFailedSearchToken);

    expect(wrapper.emitted('filterJobsBySearch')).toEqual([[mockFailedSearchToken]]);
  });
});
