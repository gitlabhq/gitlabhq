import { GlFilteredSearch } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import {
  OPERATORS_IS,
  TOKEN_TITLE_STATUS,
  TOKEN_TYPE_STATUS,
} from '~/vue_shared/components/filtered_search_bar/constants';
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

  const createComponent = (props) => {
    wrapper = shallowMount(JobsFilteredSearch, {
      propsData: {
        ...props,
      },
    });
  };

  it('displays filtered search', () => {
    createComponent();

    expect(findFilteredSearch().exists()).toBe(true);
  });

  it('displays status token', () => {
    createComponent();

    expect(findStatusToken()).toMatchObject({
      type: TOKEN_TYPE_STATUS,
      icon: 'status',
      title: TOKEN_TITLE_STATUS,
      unique: true,
      operators: OPERATORS_IS,
    });
  });

  it('emits filter token to parent component', () => {
    createComponent();

    findFilteredSearch().vm.$emit('submit', mockFailedSearchToken);

    expect(wrapper.emitted('filterJobsBySearch')).toEqual([[mockFailedSearchToken]]);
  });

  it('filtered search value is empty array when no query string is passed', () => {
    createComponent();

    expect(findFilteredSearch().props('value')).toEqual([]);
  });

  it('filtered search returns correct data shape when passed query string', () => {
    const value = 'SUCCESS';

    createComponent({ queryString: { statuses: value } });

    expect(findFilteredSearch().props('value')).toEqual([
      { type: TOKEN_TYPE_STATUS, value: { data: value, operator: '=' } },
    ]);
  });
});
