import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import createState from '~/static_site_editor/store/state';
import Success from '~/static_site_editor/pages/success.vue';
import SavedChangesMessage from '~/static_site_editor/components/saved_changes_message.vue';
import { savedContentMeta, returnUrl } from '../mock_data';
import { HOME_ROUTE } from '~/static_site_editor/router/constants';

const localVue = createLocalVue();

localVue.use(Vuex);

describe('static_site_editor/pages/success', () => {
  let wrapper;
  let store;
  let router;

  const buildRouter = () => {
    router = {
      push: jest.fn(),
    };
  };

  const buildStore = (initialState = {}) => {
    store = new Vuex.Store({
      state: createState({
        savedContentMeta,
        returnUrl,
        ...initialState,
      }),
    });
  };

  const buildWrapper = () => {
    wrapper = shallowMount(Success, {
      localVue,
      store,
      mocks: {
        $router: router,
      },
    });
  };

  const findSavedChangesMessage = () => wrapper.find(SavedChangesMessage);

  beforeEach(() => {
    buildRouter();
    buildStore();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders saved changes message', () => {
    buildWrapper();

    expect(findSavedChangesMessage().exists()).toBe(true);
  });

  it('passes returnUrl to the saved changes message', () => {
    buildWrapper();

    expect(findSavedChangesMessage().props('returnUrl')).toBe(returnUrl);
  });

  it('passes saved content metadata to the saved changes message', () => {
    buildWrapper();

    expect(findSavedChangesMessage().props('branch')).toBe(savedContentMeta.branch);
    expect(findSavedChangesMessage().props('commit')).toBe(savedContentMeta.commit);
    expect(findSavedChangesMessage().props('mergeRequest')).toBe(savedContentMeta.mergeRequest);
  });

  it('redirects to the HOME route when content has not been submitted', () => {
    buildStore({ savedContentMeta: null });
    buildWrapper();

    expect(router.push).toHaveBeenCalledWith(HOME_ROUTE);
  });
});
