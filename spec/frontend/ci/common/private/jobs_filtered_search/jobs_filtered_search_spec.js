import { GlFilteredSearch } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import {
  OPERATORS_IS,
  TOKEN_TITLE_STATUS,
  TOKEN_TYPE_STATUS,
  TOKEN_TYPE_JOBS_RUNNER_TYPE,
  TOKEN_TITLE_JOBS_RUNNER_TYPE,
} from '~/vue_shared/components/filtered_search_bar/constants';
import JobsFilteredSearch from '~/ci/common/private/jobs_filtered_search/app.vue';
import { mockFailedSearchToken } from 'jest/ci/jobs_mock_data';

describe('Jobs filtered search', () => {
  let wrapper;

  const findFilteredSearch = () => wrapper.findComponent(GlFilteredSearch);
  const getSearchToken = (type) =>
    findFilteredSearch()
      .props('availableTokens')
      .find((token) => token.type === type);

  const findStatusToken = () => getSearchToken('status');
  const findRunnerTypeToken = () => getSearchToken('jobs-runner-type');

  const createComponent = (props, provideOptions = {}) => {
    wrapper = shallowMount(JobsFilteredSearch, {
      propsData: {
        ...props,
      },
      provide: {
        glFeatures: { adminJobsFilterRunnerType: true },
        ...provideOptions,
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

  it('displays token for runner type', () => {
    createComponent();

    expect(findRunnerTypeToken()).toMatchObject({
      type: TOKEN_TYPE_JOBS_RUNNER_TYPE,
      title: TOKEN_TITLE_JOBS_RUNNER_TYPE,
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

  describe('with query string passed', () => {
    it('filtered search returns correct data shape', () => {
      const tokenStatusesValue = 'SUCCESS';
      const tokenRunnerTypesValue = 'INSTANCE_VALUE';

      createComponent({
        queryString: { statuses: tokenStatusesValue, runnerTypes: tokenRunnerTypesValue },
      });

      expect(findFilteredSearch().props('value')).toEqual([
        { type: TOKEN_TYPE_STATUS, value: { data: tokenStatusesValue, operator: '=' } },
        {
          type: TOKEN_TYPE_JOBS_RUNNER_TYPE,
          value: { data: tokenRunnerTypesValue, operator: '=' },
        },
      ]);
    });
  });

  describe('when feature flag `adminJobsFilterRunnerType` is disabled', () => {
    const provideOptions = { glFeatures: { adminJobsFilterRunnerType: false } };

    it('does not display token for runner type', () => {
      createComponent(null, provideOptions);

      expect(findRunnerTypeToken()).toBeUndefined();
    });

    describe('with query string passed', () => {
      it('filtered search returns only data shape for search token `status` and not for search token `jobs runner type`', () => {
        const tokenStatusesValue = 'SUCCESS';
        const tokenRunnerTypesValue = 'INSTANCE_VALUE';

        createComponent(
          { queryString: { statuses: tokenStatusesValue, runnerTypes: tokenRunnerTypesValue } },
          provideOptions,
        );

        expect(findFilteredSearch().props('value')).toEqual([
          { type: TOKEN_TYPE_STATUS, value: { data: tokenStatusesValue, operator: '=' } },
        ]);
      });
    });
  });
});
