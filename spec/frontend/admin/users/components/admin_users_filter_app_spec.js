import { GlFilteredSearch } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { visitUrl, getBaseURL } from '~/lib/utils/url_utility';
import AdminUsersFilterApp from '~/admin/users/components/admin_users_filter_app.vue';
import {
  FILTER_TOKEN_CONFIGS,
  STANDARD_TOKEN_CONFIGS,
} from 'ee_else_ce_jest/admin/users/mock_data';
import { OPERATOR_IS } from '~/vue_shared/components/filtered_search_bar/constants';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

const getExpectedTokenConfigs = (config) => {
  return FILTER_TOKEN_CONFIGS.includes(config)
    ? [config, ...STANDARD_TOKEN_CONFIGS]
    : [...FILTER_TOKEN_CONFIGS, ...STANDARD_TOKEN_CONFIGS];
};

describe('AdminUsersFilterApp', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(AdminUsersFilterApp, {});
  };

  const findFilteredSearch = () => wrapper.findComponent(GlFilteredSearch);
  const findAvailableTokens = () => findFilteredSearch().props('availableTokens');

  const emitInputEventForConfig = (config, data = 'value') => {
    findFilteredSearch().vm.$emit('input', [
      {
        type: config.type,
        value: { data, operator: OPERATOR_IS },
      },
    ]);
  };

  it('includes all token configs', () => {
    createComponent();

    expect(findAvailableTokens()).toEqual(getExpectedTokenConfigs());
  });

  describe.each(FILTER_TOKEN_CONFIGS)('when $type filter is selected', (config) => {
    beforeEach(() => {
      createComponent();
      return emitInputEventForConfig(config);
    });

    /**
     * Currently BE only supports one filter token config at a time
     * https://gitlab.com/gitlab-org/gitlab/-/issues/254377
     */
    it(`includes only the ${config.type} filter token config`, () => {
      expect(findAvailableTokens()).toEqual(getExpectedTokenConfigs(config));
    });
  });

  // 'filtered-search-item' is for a text search.
  it.each([...STANDARD_TOKEN_CONFIGS, { type: 'filtered-search-item' }])(
    'includes all token configs when $type filter is selected',
    (config) => {
      createComponent();
      emitInputEventForConfig(config);

      expect(findAvailableTokens()).toEqual(getExpectedTokenConfigs());
    },
  );

  describe('when the querystring has a filter parameter', () => {
    describe.each(FILTER_TOKEN_CONFIGS)('for the $type config', (config) => {
      /**
       * Currently BE only supports one filter token config at a time
       * https://gitlab.com/gitlab-org/gitlab/-/issues/254377
       */
      it.each(config.options)(
        `includes only ${config.type} filter token config when filter parameter is $value`,
        (option) => {
          window.history.replaceState({}, '', `?filter=${option.value}`);
          createComponent();

          expect(findAvailableTokens()).toEqual(getExpectedTokenConfigs(config));
        },
      );
    });
  });

  it.each([...STANDARD_TOKEN_CONFIGS, { type: 'search_query' }, { type: 'invalid' }])(
    'includes all token configs when the querystring is ?$type=someValue',
    (config) => {
      window.history.replaceState({}, '', `?${config.type}=someValue`);
      createComponent();

      expect(findAvailableTokens()).toEqual(getExpectedTokenConfigs());
    },
  );

  it('visits expected URL when filtered search is submitted', () => {
    // Set up an existing querystring to verify that the filter changes and sort is not touched.
    window.history.replaceState({}, '', '/?filter=banned&sort=oldest_sign_in');
    createComponent();
    emitInputEventForConfig(FILTER_TOKEN_CONFIGS[0], 'admins');
    findFilteredSearch().vm.$emit('submit', [
      { type: 'access_level', value: { data: 'admins', operator: '=' } },
      'mytext',
    ]);

    expect(visitUrl).toHaveBeenCalledWith(
      `${getBaseURL()}/?filter=admins&search_query=mytext&sort=oldest_sign_in`,
    );
  });
});
