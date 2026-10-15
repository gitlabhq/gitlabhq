import { GlButton } from '@gitlab/ui';
import { createTestingPinia } from '@pinia/testing';
import Vue from 'vue';
import { PiniaVuePlugin } from 'pinia';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { useAccessTokens } from '~/vue_shared/access_tokens/stores/access_tokens';
import AccessTokenStatistics from '~/vue_shared/access_tokens/components/access_token_statistics.vue';

Vue.use(PiniaVuePlugin);

describe('AccessTokenStatistics', () => {
  let wrapper;

  const pinia = createTestingPinia();
  const store = useAccessTokens();
  let $router;

  const createComponent = ({ query = {} } = {}) => {
    $router = { currentRoute: { query }, push: jest.fn() };
    wrapper = mountExtended(AccessTokenStatistics, {
      pinia,
      mocks: {
        $router,
      },
    });
  };

  const findButton = () => wrapper.findComponent(GlButton);

  const statistics = [
    {
      title: 'Active tokens',
      tooltipTitle: 'Filter tokens for active tokens',
      value: 1,
      filters: [
        {
          type: 'state',
          value: {
            data: 'active',
            operator: '=',
          },
        },
      ],
    },
  ];

  it('fetches tokens with respective filters when `Filter list` is clicked', () => {
    store.statistics = statistics;
    createComponent();

    findButton().trigger('click');

    expect(store.setFilters).toHaveBeenCalledWith([
      { type: 'state', value: { data: 'active', operator: '=' } },
    ]);
    expect(store.setPage).toHaveBeenCalledWith(1);
    expect($router.push).toHaveBeenCalledWith({ query: { page: 1, sort: 'expires_asc' } });
    expect(store.fetchTokens).toHaveBeenCalledTimes(1);
  });

  it('does not navigate when `Filter list` is clicked for the current query', () => {
    store.statistics = statistics;
    createComponent({ query: { page: '1', sort: 'expires_asc' } });

    findButton().trigger('click');

    expect($router.push).not.toHaveBeenCalled();
    expect(store.fetchTokens).toHaveBeenCalledTimes(1);
  });
});
