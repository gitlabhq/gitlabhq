import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';
import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { GlPagination, GlFilteredSearch } from '@gitlab/ui';
import enabledKeys from 'test_fixtures/deploy_keys/enabled_keys.json';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { captureException } from '~/sentry/sentry_browser_wrapper';
import { mapDeployKey } from '~/deploy_keys/graphql/resolvers';
import deployKeysQuery from '~/deploy_keys/graphql/queries/deploy_keys.query.graphql';
import deployKeysApp from '~/deploy_keys/components/app.vue';
import ConfirmModal from '~/deploy_keys/components/confirm_modal.vue';
import NavigationTabs from '~/vue_shared/components/navigation_tabs.vue';
import KeysPanel from '~/deploy_keys/components/keys_panel.vue';
import axios from '~/lib/utils/axios_utils';

jest.mock('~/sentry/sentry_browser_wrapper');

Vue.use(VueApollo);

describe('Deploy keys app component', () => {
  let wrapper;
  let mock;
  let deployKeyMock;
  let currentPageMock;
  let currentScopeMock;
  let confirmRemoveKeyMock;
  let pageInfoMock;
  let pageMutationMock;
  let scopeMutationMock;
  let disableKeyMock;
  let resolvers;

  const mountComponent = () => {
    const apolloProvider = createMockApollo([[deployKeysQuery, deployKeyMock]], resolvers);

    wrapper = mount(deployKeysApp, {
      propsData: {
        projectPath: 'test/project',
        projectId: '8',
      },
      apolloProvider,
    });

    return waitForPromises();
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    deployKeyMock = jest.fn();
    currentPageMock = jest.fn();
    currentScopeMock = jest.fn();
    confirmRemoveKeyMock = jest.fn();
    pageInfoMock = jest.fn();
    scopeMutationMock = jest.fn();
    pageMutationMock = jest.fn();
    disableKeyMock = jest.fn();

    resolvers = {
      Query: {
        currentPage: currentPageMock,
        currentScope: currentScopeMock,
        deployKeyToRemove: confirmRemoveKeyMock,
        pageInfo: pageInfoMock,
      },
      Mutation: {
        currentPage: pageMutationMock,
        currentScope: scopeMutationMock,
        disableKey: disableKeyMock,
      },
    };
  });

  afterEach(() => {
    mock.restore();
  });

  const findLoadingIcon = () => wrapper.find('.gl-spinner');
  const findKeyPanels = () => wrapper.findAll('.deploy-keys .gl-tabs-nav li');
  const findModal = () => wrapper.findComponent(ConfirmModal);
  const findNavigationTabs = () => wrapper.findComponent(NavigationTabs);
  const findFilteredSearch = () => wrapper.findComponent(GlFilteredSearch);
  const findKeysPanel = () => wrapper.findComponent(KeysPanel);

  it('renders loading icon while waiting for request', async () => {
    currentScopeMock.mockResolvedValue('enabledKeys');
    currentPageMock.mockResolvedValue(1);
    deployKeyMock.mockReturnValue(new Promise(() => {}));
    mountComponent();

    await waitForPromises();
    await nextTick();
    expect(findLoadingIcon().exists()).toBe(true);
  });

  it('renders keys panels', async () => {
    const deployKeys = enabledKeys.keys.map(mapDeployKey);
    deployKeyMock.mockReturnValue({
      data: {
        project: { id: 1, deployKeys, __typename: 'Project' },
      },
    });
    await mountComponent();
    expect(findKeyPanels().length).toBe(3);
  });

  describe.each`
    scope
    ${'enabledKeys'}
    ${'availableProjectKeys'}
    ${'availablePublicKeys'}
  `('tab $scope', ({ scope }) => {
    let selector;

    beforeEach(async () => {
      selector = `.js-deployKeys-tab-${scope}`;
      const deployKeys = enabledKeys.keys.map(mapDeployKey);
      deployKeyMock.mockReturnValue({
        data: {
          project: { id: 1, deployKeys, __typename: 'Project' },
        },
      });

      await mountComponent();
    });

    it('displays the title', () => {
      const element = wrapper.find(selector);
      expect(element.exists()).toBe(true);
    });

    it('triggers changing the scope on click', async () => {
      await findNavigationTabs().vm.$emit('onChangeTab', scope);

      expect(scopeMutationMock).toHaveBeenCalledWith(
        expect.anything(),
        { scope },
        expect.anything(),
        expect.anything(),
      );
    });
  });

  it('captures a failed tab change', async () => {
    const scope = 'fake scope';
    const error = new Error('fail!');

    const deployKeys = enabledKeys.keys.map(mapDeployKey);
    deployKeyMock.mockReturnValue({
      data: {
        project: { id: 1, deployKeys, __typename: 'Project' },
      },
    });

    scopeMutationMock.mockRejectedValue(error);
    await mountComponent();
    await findNavigationTabs().vm.$emit('onChangeTab', scope);
    await waitForPromises();

    expect(captureException).toHaveBeenCalledWith(error, { tags: { deployKeyScope: scope } });
  });

  it('hasKeys returns true when there are keys', async () => {
    const deployKeys = enabledKeys.keys.map(mapDeployKey);
    deployKeyMock.mockReturnValue({
      data: {
        project: { id: 1, deployKeys, __typename: 'Project' },
      },
    });
    await mountComponent();

    expect(findNavigationTabs().exists()).toBe(true);
    expect(findLoadingIcon().exists()).toBe(false);
  });

  describe('disabling keys', () => {
    const key = mapDeployKey(enabledKeys.keys[0]);

    beforeEach(() => {
      deployKeyMock.mockReturnValue({
        data: {
          project: { id: 1, deployKeys: [key], __typename: 'Project' },
        },
      });
    });

    it('re-fetches deploy keys when disabling a key', async () => {
      currentScopeMock.mockResolvedValue('enabledKeys');
      currentPageMock.mockResolvedValue(1);
      confirmRemoveKeyMock.mockReturnValue(key);
      await mountComponent();
      expect(deployKeyMock).toHaveBeenCalledTimes(1);

      await nextTick();
      expect(findModal().props('visible')).toBe(true);
      findModal().vm.$emit('remove');
      await waitForPromises();
      expect(deployKeyMock).toHaveBeenCalledTimes(2);
    });
  });

  describe('pagination', () => {
    const key = mapDeployKey(enabledKeys.keys[0]);
    let page;
    let pageInfo;
    let glPagination;

    beforeEach(async () => {
      page = 2;
      pageInfo = {
        total: 20,
        perPage: 5,
        nextPage: 3,
        page,
        previousPage: 1,
        __typename: 'LocalPageInfo',
      };
      deployKeyMock.mockReturnValue({
        data: {
          project: { id: 1, deployKeys: [], __typename: 'Project' },
        },
      });

      confirmRemoveKeyMock.mockReturnValue(key);
      pageInfoMock.mockReturnValue(pageInfo);
      currentPageMock.mockReturnValue(page);
      await mountComponent();
      glPagination = wrapper.findComponent(GlPagination);
    });

    it('shows pagination with correct page info', () => {
      expect(glPagination.exists()).toBe(true);
      expect(glPagination.props()).toMatchObject({
        totalItems: pageInfo.total,
        perPage: pageInfo.perPage,
        value: page,
      });
    });

    it('moves back a page', async () => {
      await glPagination.vm.$emit('previous');

      expect(pageMutationMock).toHaveBeenCalledWith(
        expect.anything(),
        { page: page - 1 },
        expect.anything(),
        expect.anything(),
      );
    });

    it('moves forward a page', async () => {
      await glPagination.vm.$emit('next');

      expect(pageMutationMock).toHaveBeenCalledWith(
        expect.anything(),
        { page: page + 1 },
        expect.anything(),
        expect.anything(),
      );
    });

    it('moves to specified page', async () => {
      await glPagination.vm.$emit('input', 5);

      expect(pageMutationMock).toHaveBeenCalledWith(
        expect.anything(),
        { page: 5 },
        expect.anything(),
        expect.anything(),
      );
    });

    it('moves a page back if there are no more keys on this page', async () => {
      await findModal().vm.$emit('remove');
      await waitForPromises();

      expect(pageMutationMock).toHaveBeenCalledWith(
        expect.anything(),
        { page: page - 1 },
        expect.anything(),
        expect.anything(),
      );
    });
  });

  describe('search functionality', () => {
    beforeEach(async () => {
      const deployKeys = enabledKeys.keys.map(mapDeployKey);
      deployKeyMock.mockReturnValue({
        data: {
          project: { id: 1, deployKeys, __typename: 'Project' },
        },
      });

      currentScopeMock.mockResolvedValue('enabledKeys');
      currentPageMock.mockResolvedValue(1);

      await mountComponent();
    });

    it('provides two token options by default', () => {
      expect(findFilteredSearch().props('availableTokens')).toHaveLength(2);
      expect(findFilteredSearch().props('availableTokens')[0].type).toBe('title');
      expect(findFilteredSearch().props('availableTokens')[1].type).toBe('key');
    });

    it('updates available tokens to the type of search', async () => {
      await findFilteredSearch().vm.$emit('input', [{ type: 'title', value: { data: 'test' } }]);
      expect(findFilteredSearch().props('availableTokens')).toHaveLength(1);
      expect(findFilteredSearch().props('availableTokens')[0].type).toBe('title');
    });

    it('removes available tokens on raw text type', async () => {
      await findFilteredSearch().vm.$emit('input', [
        { id: 'token-28', type: 'filtered-search-term', value: { data: 'test' } },
      ]);
      expect(findFilteredSearch().props('availableTokens')).toHaveLength(0);
    });

    it('handles search submission', async () => {
      expect(deployKeyMock).toHaveBeenCalledTimes(1);

      await findFilteredSearch().vm.$emit('submit', [{ type: 'key', value: { data: 'test' } }]);
      expect(deployKeyMock).toHaveBeenCalledTimes(2);
      expect(deployKeyMock).toHaveBeenNthCalledWith(2, {
        page: 1,
        projectPath: 'test/project',
        scope: 'enabledKeys',
        search: { in: 'key', search: 'test' },
      });
    });

    it('renders as view-only when the query is loading', async () => {
      await findFilteredSearch().vm.$emit('submit', [{ type: 'key', value: { data: 'test' } }]);
      expect(findFilteredSearch().props('viewOnly')).toBe(true);

      await waitForPromises();
      expect(findFilteredSearch().props('viewOnly')).toBe(false);
    });

    it('clears search value when tab changes', async () => {
      await findFilteredSearch().vm.$emit('submit', [{ type: 'title', value: { data: 'test' } }]);
      await findNavigationTabs().vm.$emit('onChangeTab', 'enabled');
      expect(findFilteredSearch().props('value')).toEqual([
        { id: expect.anything(), type: 'filtered-search-term', value: { data: '' } },
      ]);
    });

    it('passes hasSearch prop to KeysPanel', async () => {
      await findFilteredSearch().vm.$emit('submit', [{ type: 'title', value: { data: 'test' } }]);
      await waitForPromises();
      expect(findKeysPanel().props('hasSearch')).toBe(true);
    });
  });
});
