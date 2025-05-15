import { GlFilteredSearch, GlPagination, GlSorting } from '@gitlab/ui';
import { createTestingPinia } from '@pinia/testing';
import Vue, { nextTick } from 'vue';
import { PiniaVuePlugin } from 'pinia';
import AccessTokens from '~/vue_shared/access_tokens/components/access_tokens.vue';
import AccessTokenForm from '~/vue_shared/access_tokens/components/access_token_form.vue';
import { useAccessTokens } from '~/vue_shared/access_tokens/stores/access_tokens';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { DEFAULT_FILTER, DEFAULT_SORT } from '~/access_tokens/constants';

Vue.use(PiniaVuePlugin);

describe('AccessTokens', () => {
  let wrapper;

  const pinia = createTestingPinia();
  const store = useAccessTokens();

  const accessTokenCreate = '/api/v4/groups/1/service_accounts/:id/personal_access_tokens/';
  const accessTokenRevoke = '/api/v4/groups/2/service_accounts/:id/personal_access_tokens/';
  const accessTokenRotate = '/api/v4/groups/3/service_accounts/:id/personal_access_tokens/';
  const accessTokenShow = '/api/v4/groups/4/service_accounts/:id/personal_access_token';
  const id = 235;

  const createComponent = () => {
    wrapper = shallowMountExtended(AccessTokens, {
      pinia,
      provide: {
        accessTokenCreate,
        accessTokenRevoke,
        accessTokenRotate,
        accessTokenShow,
      },
      propsData: {
        id,
      },
    });
  };

  const findCreateTokenButton = () => wrapper.findByTestId('add-new-token-button');
  const findCreateTokenForm = () => wrapper.findComponent(AccessTokenForm);
  const findFilteredSearch = () => wrapper.findComponent(GlFilteredSearch);
  const findPagination = () => wrapper.findComponent(GlPagination);
  const findSorting = () => wrapper.findComponent(GlSorting);

  it('fetches tokens when it is rendered', () => {
    createComponent();
    waitForPromises();

    expect(store.setup).toHaveBeenCalledWith({
      filters: DEFAULT_FILTER,
      id: 235,
      page: 1,
      sorting: DEFAULT_SORT,
      urlCreate: '/api/v4/groups/1/service_accounts/:id/personal_access_tokens/',
      urlRevoke: '/api/v4/groups/2/service_accounts/:id/personal_access_tokens/',
      urlRotate: '/api/v4/groups/3/service_accounts/:id/personal_access_tokens/',
      urlShow: '/api/v4/groups/4/service_accounts/:id/personal_access_token',
    });
    expect(store.fetchTokens).toHaveBeenCalledTimes(1);
  });

  describe('when clicking on the add new token button', () => {
    it('clears the current token', () => {
      createComponent();
      expect(store.setToken).toHaveBeenCalledTimes(0);
      findCreateTokenButton().vm.$emit('click');

      expect(store.setToken).toHaveBeenCalledWith(null);
    });

    it('shows the token creation form', async () => {
      createComponent();
      expect(findCreateTokenForm().exists()).toBe(false);
      findCreateTokenButton().vm.$emit('click');

      expect(store.setShowCreateForm).toHaveBeenCalledWith(true);
      store.showCreateForm = true;
      await nextTick();

      expect(findCreateTokenForm().exists()).toBe(true);
    });
  });

  it('fetches tokens when the page is changed', () => {
    createComponent();
    expect(store.fetchTokens).toHaveBeenCalledTimes(1);
    findPagination().vm.$emit('input', 2);

    expect(store.fetchTokens).toHaveBeenCalledTimes(2);
  });

  it('fetches tokens when filters are changed', () => {
    createComponent();
    expect(store.fetchTokens).toHaveBeenCalledTimes(1);
    findFilteredSearch().vm.$emit('submit', ['my token']);

    expect(store.fetchTokens).toHaveBeenCalledTimes(2);
  });

  it('sets the sorting and fetches tokens when sorting option is changed', () => {
    createComponent();
    expect(store.fetchTokens).toHaveBeenCalledTimes(1);
    findSorting().vm.$emit('sortByChange', 'name');

    expect(store.setSorting).toHaveBeenCalledWith(expect.objectContaining({ value: 'name' }));
    expect(store.fetchTokens).toHaveBeenCalledTimes(2);
  });

  it('sets the sorting and fetches tokens when sorting direction is changed', () => {
    createComponent();
    expect(store.fetchTokens).toHaveBeenCalledTimes(1);
    store.sorting = { value: 'name', isAsc: true };
    findSorting().vm.$emit('sortDirectionChange', false);

    expect(store.setSorting).toHaveBeenCalledWith(expect.objectContaining({ isAsc: false }));
    expect(store.fetchTokens).toHaveBeenCalledTimes(2);
  });
});
