import Vue, { nextTick } from 'vue';
import { PiniaVuePlugin } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { useAccessTokens } from '~/vue_shared/access_tokens/stores/access_tokens';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import AccessTokenForm from '~/vue_shared/access_tokens/components/access_token_form.vue';
import CreatedPersonalAccessToken from '~/personal_access_tokens/components/created_personal_access_token.vue';
import CreateLegacyPersonalAccessTokenForm from '~/personal_access_tokens/components/create_legacy_token/create_legacy_personal_access_token_form.vue';

Vue.use(PiniaVuePlugin);

describe('CreateLegacyPersonalAccessTokenForm', () => {
  let wrapper;
  let pinia;
  let store;

  const accessTokenCreate = '/-/personal_access_tokens';
  const accessTokenTableUrl = '/-/personal_access_tokens';

  const createComponent = () => {
    wrapper = shallowMountExtended(CreateLegacyPersonalAccessTokenForm, {
      pinia,
      provide: {
        accessTokenCreate,
        accessTokenTableUrl,
      },
    });
  };

  const findPageHeading = () => wrapper.findComponent(PageHeading);
  const findAccessTokenForm = () => wrapper.findComponent(AccessTokenForm);
  const findCreatedToken = () => wrapper.findComponent(CreatedPersonalAccessToken);

  beforeEach(() => {
    pinia = createTestingPinia();
    store = useAccessTokens();

    createComponent();
  });

  it('sets `showCreateFormInline` in the store to false', () => {
    expect(store.setup).toHaveBeenCalledWith({
      showCreateFormInline: false,
      urlCreate: accessTokenCreate,
    });
  });

  it('renders the page heading', () => {
    expect(findPageHeading().exists()).toBe(true);
    expect(findPageHeading().props('heading')).toBe('Generate legacy token');
    expect(findPageHeading().text()).toContain(
      'Legacy personal access tokens are scoped to all groups and projects with broad permissions to resources.',
    );
  });

  it('renders access token form when token is not created', () => {
    expect(findAccessTokenForm().exists()).toBe(true);
  });

  it('renders created token component when token exists', async () => {
    const tokenValue = 'xx';
    store.token = tokenValue;

    await nextTick();

    expect(findCreatedToken().exists()).toBe(true);
    expect(findCreatedToken().props('value')).toBe(tokenValue);

    expect(findAccessTokenForm().exists()).toBe(false);
  });
});
