import { GlFilteredSearch, GlPagination, GlSorting } from '@gitlab/ui';
import { createTestingPinia } from '@pinia/testing';
import Vue, { nextTick } from 'vue';
import { PiniaVuePlugin } from 'pinia';
import AccessTokens from '~/vue_shared/access_tokens/components/access_tokens.vue';
import AccessTokenForm from '~/vue_shared/access_tokens/components/access_token_form.vue';
import UserAvatar from '~/vue_shared/access_tokens/components/user_avatar.vue';
import { useAccessTokens } from '~/vue_shared/access_tokens/stores/access_tokens';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { DEFAULT_FILTER, DEFAULT_SORT } from '~/access_tokens/constants';
import TokenAccessTable from '~/vue_shared/access_tokens/components/access_token_table.vue';
import PersonalAccessTokensCrud from '~/vue_shared/access_tokens/components/personal_access_tokens/tokens_crud.vue';
import { stubComponent } from 'helpers/stub_component';

Vue.use(PiniaVuePlugin);

describe('AccessTokens', () => {
  let wrapper;

  const pinia = createTestingPinia();
  const store = useAccessTokens();
  const tokens = [{ name: 'A' }, { name: 'B' }];
  const $router = {
    push: jest.fn(),
    replace: jest.fn(),
  };

  const accessTokenCreate =
    'http://localhost/api/v4/groups/1/service_accounts/:id/personal_access_tokens/';
  const accessTokenRevoke =
    'http://localhost/api/v4/groups/2/service_accounts/:id/personal_access_tokens/';
  const accessTokenRotate =
    'http://localhost/api/v4/groups/3/service_accounts/:id/personal_access_tokens/';
  const accessTokenShow =
    'http://localhost/api/v4/groups/4/service_accounts/:id/personal_access_token';
  const id = 235;

  const createComponent = ({
    tokenName,
    tokenDescription,
    tokenScopes,
    showAvatar = false,
    useFineGrainedTokens = true,
  } = {}) => {
    wrapper = shallowMountExtended(AccessTokens, {
      pinia,
      provide: {
        accessTokenCreate,
        accessTokenRevoke,
        accessTokenRotate,
        accessTokenShow,
      },
      propsData: { id, tokenName, tokenDescription, tokenScopes, showAvatar, useFineGrainedTokens },
      stubs: {
        PersonalAccessTokensCrud: stubComponent(PersonalAccessTokensCrud, {
          props: ['tokens', 'loading'],
        }),
      },
      mocks: {
        $router,
      },
    });
  };

  beforeEach(() => {
    store.showCreateForm = false;
  });

  const findCreateTokenButton = () => wrapper.findByTestId('add-new-token-button');
  const findCreateTokenForm = () => wrapper.findComponent(AccessTokenForm);
  const findFilteredSearch = () => wrapper.findComponent(GlFilteredSearch);
  const findPagination = () => wrapper.findComponent(GlPagination);
  const findSorting = () => wrapper.findComponent(GlSorting);
  const findUserAvatar = () => wrapper.findComponent(UserAvatar);
  const findTokenAccessTable = () => wrapper.findComponent(TokenAccessTable);
  const findPersonalAccessTokensCrud = () => wrapper.findComponent(PersonalAccessTokensCrud);

  it('fetches tokens when it is rendered', () => {
    createComponent();
    waitForPromises();

    expect($router.replace).toHaveBeenCalledWith({ query: { page: 1, sort: 'expires_asc' } });
    expect(store.setup).toHaveBeenCalledWith({
      filters: DEFAULT_FILTER,
      id: 235,
      page: 1,
      showCreateForm: false,
      sorting: DEFAULT_SORT,
      urlCreate: 'http://localhost/api/v4/groups/1/service_accounts/:id/personal_access_tokens/',
      urlRevoke: 'http://localhost/api/v4/groups/2/service_accounts/:id/personal_access_tokens/',
      urlRotate: 'http://localhost/api/v4/groups/3/service_accounts/:id/personal_access_tokens/',
      urlShow: 'http://localhost/api/v4/groups/4/service_accounts/:id/personal_access_token',
    });
    expect(store.fetchTokens).toHaveBeenCalledTimes(1);
  });

  describe('when token name, description or scopes are provided', () => {
    it('shows the token creation form', async () => {
      createComponent({
        tokenName: 'My token',
        tokenDescription: 'My description',
        tokenScopes: ['api', 'sudo'],
      });
      waitForPromises();

      expect(store.setup).toHaveBeenCalledWith(expect.objectContaining({ showCreateForm: true }));
      store.showCreateForm = true;
      await nextTick();

      expect(findCreateTokenForm().props()).toMatchObject({
        name: 'My token',
        description: 'My description',
        scopes: ['api', 'sudo'],
      });
    });
  });

  describe('user avatar', () => {
    it('hides the user avatar', () => {
      createComponent();

      expect(findUserAvatar().exists()).toBe(false);
    });

    it('shows the user avatar', () => {
      createComponent({ showAvatar: true });

      expect(findUserAvatar().exists()).toBe(true);
    });
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

  it('fetches tokens when filters are changed', () => {
    createComponent();
    expect(store.fetchTokens).toHaveBeenCalledTimes(1);
    findFilteredSearch().vm.$emit('submit', ['my token']);

    expect($router.push).toHaveBeenCalledWith({ query: { page: 1, sort: 'expires_asc' } });
    expect(store.fetchTokens).toHaveBeenCalledTimes(2);
  });

  it('sets the url params correctly and fetches tokens when window `popstate` event is triggered', () => {
    createComponent();
    expect(store.fetchTokens).toHaveBeenCalledTimes(1);
    window.dispatchEvent(new Event('popstate'));

    expect(store.setFilters).toHaveBeenCalledTimes(1);
    expect(store.setPage).toHaveBeenCalledWith(1);
    expect(store.setSorting).toHaveBeenCalledTimes(1);
    expect(store.fetchTokens).toHaveBeenCalledTimes(2);
  });

  it('fetches tokens when the page is changed', () => {
    createComponent();
    expect(store.fetchTokens).toHaveBeenCalledTimes(1);
    findPagination().vm.$emit('input', 2);

    expect($router.push).toHaveBeenCalledWith({ query: { page: 1, sort: 'expires_asc' } });
    expect(store.fetchTokens).toHaveBeenCalledTimes(2);
  });

  it('sets the sorting and fetches tokens when sorting option is changed', () => {
    createComponent();
    expect(store.fetchTokens).toHaveBeenCalledTimes(1);
    findSorting().vm.$emit('sortByChange', 'name');

    expect($router.push).toHaveBeenCalledWith({ query: { page: 1, sort: 'expires_asc' } });
    expect(store.setSorting).toHaveBeenCalledWith(expect.objectContaining({ value: 'name' }));
    expect(store.fetchTokens).toHaveBeenCalledTimes(2);
  });

  it('sets the sorting and fetches tokens when sorting direction is changed', () => {
    createComponent();
    expect(store.fetchTokens).toHaveBeenCalledTimes(1);
    store.sorting = { value: 'name', isAsc: true };
    findSorting().vm.$emit('sortDirectionChange', false);

    expect($router.push).toHaveBeenCalledWith({ query: { page: 1, sort: 'name_asc' } });
    expect(store.setSorting).toHaveBeenCalledWith(expect.objectContaining({ isAsc: false }));
    expect(store.fetchTokens).toHaveBeenCalledTimes(2);
  });

  describe('on page load', () => {
    beforeEach(() => {
      store.tokens = tokens;
      createComponent();
    });

    it('shows personal access tokens crud', () => {
      expect(findPersonalAccessTokensCrud().props()).toEqual({
        tokens,
        loading: false,
      });
    });

    it('does not show access token table', () => {
      expect(findTokenAccessTable().exists()).toBe(false);
    });
  });

  describe('when fineGrainedPersonalAccessTokens feature flag is disabled', () => {
    beforeEach(() => {
      store.tokens = tokens;
      createComponent({ useFineGrainedTokens: false });
    });

    it('shows access token table', () => {
      expect(findTokenAccessTable().props()).toEqual({
        tokens,
        busy: false,
      });
    });

    it('does not show personal access tokens crud', () => {
      expect(findPersonalAccessTokensCrud().exists()).toBe(false);
    });
  });

  describe('busy state', () => {
    beforeEach(() => {
      store.busy = true;
    });

    it('shows personal access tokens crud as loading', () => {
      createComponent();

      expect(findPersonalAccessTokensCrud().props('loading')).toBe(true);
    });

    it('shows access token table as busy', () => {
      createComponent({ useFineGrainedTokens: false });

      expect(findTokenAccessTable().props('busy')).toBe(true);
    });
  });
});
