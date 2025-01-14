import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import {
  GlPagination,
  GlSkeletonLoader,
  GlTabs,
  GlTab,
  GlLoadingIcon,
  GlSearchBoxByType,
} from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import setWindowLocation from 'helpers/set_window_location_helper';
import { stubComponent } from 'helpers/stub_component';
import { sprintf } from '~/locale';
import EnvironmentsApp from '~/environments/components/environments_app.vue';
import EnvironmentsFolder from '~/environments/components/environment_folder.vue';
import EnvironmentsItem from '~/environments/components/new_environment_item.vue';
import EmptyState from '~/environments/components/empty_state.vue';
import StopEnvironmentModal from '~/environments/components/stop_environment_modal.vue';
import CanaryUpdateModal from '~/environments/components/canary_update_modal.vue';
import { resolvedEnvironmentsApp, resolvedFolder, resolvedEnvironment } from './graphql/mock_data';

Vue.use(VueApollo);

describe('~/environments/components/environments_app.vue', () => {
  let wrapper;
  let environmentAppMock;
  let environmentFolderMock;
  let paginationMock;
  let environmentToStopMock;
  let environmentToChangeCanaryMock;
  let weightMock;

  const GlTabStub = stubComponent(GlTab, {
    template: '<li><slot name="title" /></li>',
  });

  const createApolloProvider = () => {
    const mockResolvers = {
      Query: {
        environmentApp: environmentAppMock,
        folder: environmentFolderMock,
        pageInfo: paginationMock,
        environmentToStop: environmentToStopMock,
        environmentToDelete: jest.fn().mockResolvedValue(resolvedEnvironment),
        environmentToRollback: jest.fn().mockResolvedValue(resolvedEnvironment),
        environmentToChangeCanary: environmentToChangeCanaryMock,
        weight: weightMock,
      },
    };

    return createMockApollo([], mockResolvers);
  };

  const createWrapper = ({ provide = {}, apolloProvider } = {}) =>
    mountExtended(EnvironmentsApp, {
      provide: {
        newEnvironmentPath: '/environments/new',
        canCreateEnvironment: true,
        defaultBranchName: 'main',
        helpPagePath: '/help',
        projectId: '1',
        projectPath: '/1',
        ...provide,
      },
      stubs: {
        GlTab: GlTabStub,
      },
      apolloProvider,
    });

  const createWrapperWithMocked = async ({
    provide = {},
    environmentsApp,
    folder,
    environmentToStop = {},
    environmentToChangeCanary = {},
    weight = 0,
    pageInfo = {
      total: 20,
      perPage: 5,
      nextPage: 3,
      page: 2,
      previousPage: 1,
      __typename: 'LocalPageInfo',
    },
    location = '?scope=active&page=2&search=prod',
  }) => {
    setWindowLocation(location);
    environmentAppMock.mockReturnValue(environmentsApp);
    environmentFolderMock.mockReturnValue(folder);
    paginationMock.mockReturnValue(pageInfo);
    environmentToStopMock.mockReturnValue(environmentToStop);
    environmentToChangeCanaryMock.mockReturnValue(environmentToChangeCanary);
    weightMock.mockReturnValue(weight);
    const apolloProvider = createApolloProvider();
    wrapper = createWrapper({ apolloProvider, provide });

    await waitForPromises();
    await nextTick();
  };

  beforeEach(() => {
    environmentAppMock = jest.fn();
    environmentFolderMock = jest.fn();
    environmentToStopMock = jest.fn();
    environmentToChangeCanaryMock = jest.fn();
    weightMock = jest.fn();
    paginationMock = jest.fn();
  });

  it('should request active environments if the scope is invalid', async () => {
    await createWrapperWithMocked({
      environmentsApp: resolvedEnvironmentsApp,
      folder: resolvedFolder,
      location: '?scope=bad&page=2&search=prod',
    });

    expect(environmentAppMock).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining({ scope: 'active', page: 2 }),
      expect.anything(),
      expect.anything(),
    );
  });

  describe('loading state', () => {
    it('should show loading state while loading data', () => {
      createWrapperWithMocked({});

      const loader = wrapper.findComponent(GlSkeletonLoader);
      expect(loader.exists()).toBe(true);
    });

    it('should show tabs while loading data', () => {
      createWrapperWithMocked({});

      const findTabs = wrapper.findComponent(GlTabs);
      expect(findTabs.exists()).toBe(true);
    });

    it('should hide loading state once received data', async () => {
      await createWrapperWithMocked({ environmentsApp: resolvedEnvironmentsApp });

      const loader = wrapper.findComponent(GlSkeletonLoader);
      expect(loader.exists()).toBe(false);
    });

    it('should show tabs title as loading when performing search', async () => {
      await createWrapperWithMocked({
        environmentsApp: resolvedEnvironmentsApp,
      });

      const searchBox = wrapper.findByRole('searchbox', {
        name: 'Search by environment name',
      });
      searchBox.setValue('hello');
      await nextTick();

      const [active, stopped] = wrapper.findAllComponents(GlTab).wrappers;

      expect(active.findComponent(GlLoadingIcon).exists()).toBe(true);
      expect(stopped.findComponent(GlLoadingIcon).exists()).toBe(true);

      await waitForPromises();

      expect(active.findComponent(GlLoadingIcon).exists()).toBe(false);
      expect(stopped.findComponent(GlLoadingIcon).exists()).toBe(false);
    });
  });

  it('should show all the folders that are fetched', async () => {
    await createWrapperWithMocked({
      environmentsApp: resolvedEnvironmentsApp,
      folder: resolvedFolder,
    });

    const text = wrapper.findAllComponents(EnvironmentsFolder).wrappers.map((w) => w.text());

    expect(text).toContainEqual(expect.stringMatching('review'));
    expect(text).not.toContainEqual(expect.stringMatching('production'));
  });

  it('should show all the environments that are fetched', async () => {
    await createWrapperWithMocked({
      environmentsApp: resolvedEnvironmentsApp,
      folder: resolvedFolder,
    });

    const text = wrapper.findAllComponents(EnvironmentsItem).wrappers.map((w) => w.text());

    expect(text).not.toContainEqual(expect.stringMatching('review'));
    expect(text).toContainEqual(expect.stringMatching('production'));
  });

  it('should show environments table headers when there are environments are present', async () => {
    await createWrapperWithMocked({
      environmentsApp: resolvedEnvironmentsApp,
      folder: resolvedFolder,
    });

    const tableHeaders = wrapper.findByTestId('environments-table-header');
    expect(tableHeaders.text()).toBe('Name Deployments Actions');
  });

  it('should show an empty state with no environments', async () => {
    await createWrapperWithMocked({
      environmentsApp: { ...resolvedEnvironmentsApp, environments: [] },
    });

    expect(wrapper.findComponent(EmptyState).exists()).toBe(true);
  });

  it('should not show environments table headers with no environment', async () => {
    await createWrapperWithMocked({
      environmentsApp: { ...resolvedEnvironmentsApp, environments: [] },
    });

    const tableHeaders = wrapper.findByTestId('environments-table-header');
    expect(tableHeaders.exists()).toBe(false);
  });

  it('should show a button to create a new environment', async () => {
    await createWrapperWithMocked({
      environmentsApp: resolvedEnvironmentsApp,
      folder: resolvedFolder,
    });

    const button = wrapper.findByRole('link', { name: 'New environment' });
    expect(button.attributes('href')).toBe('/environments/new');
  });

  it('should not show a button to create a new environment if the user has no permissions', async () => {
    await createWrapperWithMocked({
      environmentsApp: resolvedEnvironmentsApp,
      folder: resolvedFolder,
      provide: { canCreateEnvironment: false, newEnvironmentPath: '' },
    });

    const button = wrapper.findByRole('link', { name: 'New environment' });
    expect(button.exists()).toBe(false);
  });

  it('should show a button to open the review app modal', async () => {
    await createWrapperWithMocked({
      environmentsApp: resolvedEnvironmentsApp,
      folder: resolvedFolder,
    });

    const button = wrapper.findByRole('button', { name: 'Enable review apps' });
    expect(button.exists()).toBe(true);
  });

  it.each`
    canSetupReviewApp | hasReviewApp
    ${false}          | ${true}
    ${true}           | ${true}
  `(
    'should not show button to open the review app modal',
    async ({ canSetupReviewApp, hasReviewApp }) => {
      await createWrapperWithMocked({
        environmentsApp: {
          ...resolvedEnvironmentsApp,
          reviewApp: { canSetupReviewApp, hasReviewApp },
        },
        folder: resolvedFolder,
      });

      const button = wrapper.findByRole('button', { name: 'Enable review apps' });
      expect(button.exists()).toBe(false);
    },
  );

  it('should not show a button to clean up environments if the user has no permissions', async () => {
    await createWrapperWithMocked({
      environmentsApp: {
        ...resolvedEnvironmentsApp,
        canStopStaleEnvironments: false,
      },
      folder: resolvedFolder,
    });

    const button = wrapper.findByRole('button', {
      name: 'Clean up environments',
    });
    expect(button.exists()).toBe(false);
  });

  it('should show a button to clean up environments if the user has permissions', async () => {
    await createWrapperWithMocked({
      environmentsApp: {
        ...resolvedEnvironmentsApp,
        canStopStaleEnvironments: true,
      },
      folder: resolvedFolder,
    });

    const button = wrapper.findByRole('button', {
      name: 'Clean up environments',
    });
    expect(button.exists()).toBe(true);
  });

  describe('tabs', () => {
    it('should show tabs for active and stopped environments', async () => {
      await createWrapperWithMocked({
        environmentsApp: resolvedEnvironmentsApp,
        folder: resolvedFolder,
      });

      const [active, stopped] = wrapper.findAllComponents(GlTab).wrappers;

      expect(active.text()).toContain('Active');
      expect(active.text()).toContain(resolvedEnvironmentsApp.activeCount.toString());
      expect(stopped.text()).toContain('Stopped');
      expect(stopped.text()).toContain(resolvedEnvironmentsApp.stoppedCount.toString());
    });

    it('should change the requested scope on tab change', async () => {
      await createWrapperWithMocked({
        environmentsApp: resolvedEnvironmentsApp,
        folder: resolvedFolder,
      });

      const stopped = wrapper.findAllComponents(GlTab).at(1);

      stopped.vm.$emit('click');

      await nextTick();
      await waitForPromises();

      expect(environmentAppMock).toHaveBeenCalledWith(
        expect.anything(),
        expect.objectContaining({ scope: 'stopped', page: 1 }),
        expect.anything(),
        expect.anything(),
      );
    });
  });

  describe('modals', () => {
    it('should pass the environment to stop to the stop environment modal', async () => {
      await createWrapperWithMocked({
        environmentsApp: resolvedEnvironmentsApp,
        folder: resolvedFolder,
        environmentToStop: resolvedEnvironment,
      });

      const modal = wrapper.findComponent(StopEnvironmentModal);

      expect(modal.props('environment')).toMatchObject(resolvedEnvironment);
    });

    it('should pass the environment to change canary to the canary update modal', async () => {
      await createWrapperWithMocked({
        environmentsApp: resolvedEnvironmentsApp,
        folder: resolvedFolder,
        environmentToChangeCanary: resolvedEnvironment,
        weight: 10,
      });

      const modal = wrapper.findComponent(CanaryUpdateModal);

      expect(modal.props('environment')).toMatchObject(resolvedEnvironment);
    });
  });

  describe('pagination', () => {
    it('should sync page from query params on load', async () => {
      await createWrapperWithMocked({
        environmentsApp: resolvedEnvironmentsApp,
        folder: resolvedFolder,
      });

      expect(wrapper.findComponent(GlPagination).props('value')).toBe(2);
    });

    it('should change the requested page on next page click', async () => {
      await createWrapperWithMocked({
        environmentsApp: resolvedEnvironmentsApp,
        folder: resolvedFolder,
      });
      const next = wrapper.findByRole('link', {
        name: 'Go to next page',
      });

      next.trigger('click');

      await nextTick();
      await waitForPromises();

      expect(environmentAppMock).toHaveBeenCalledWith(
        expect.anything(),
        expect.objectContaining({ page: 3 }),
        expect.anything(),
        expect.anything(),
      );
    });

    it('should change the requested page on previous page click', async () => {
      await createWrapperWithMocked({
        environmentsApp: resolvedEnvironmentsApp,
        folder: resolvedFolder,
      });
      const prev = wrapper.findByRole('link', {
        name: 'Go to previous page',
      });

      prev.trigger('click');

      await nextTick();
      await waitForPromises();

      expect(environmentAppMock).toHaveBeenCalledWith(
        expect.anything(),
        expect.objectContaining({ page: 1 }),
        expect.anything(),
        expect.anything(),
      );
    });

    it('should change the requested page on specific page click', async () => {
      await createWrapperWithMocked({
        environmentsApp: resolvedEnvironmentsApp,
        folder: resolvedFolder,
      });

      const page = 1;
      const pageButton = wrapper.findByRole('link', {
        name: sprintf('Go to page %{page}', { page }),
      });

      pageButton.trigger('click');

      await nextTick();
      await waitForPromises();

      expect(environmentAppMock).toHaveBeenCalledWith(
        expect.anything(),
        expect.objectContaining({ page }),
        expect.anything(),
        expect.anything(),
      );
    });

    it('should sync the query params to the new page', async () => {
      await createWrapperWithMocked({
        environmentsApp: resolvedEnvironmentsApp,
        folder: resolvedFolder,
      });
      const next = wrapper.findByRole('link', {
        name: 'Go to next page',
      });

      next.trigger('click');

      await nextTick();
      expect(window.location.search).toBe('?scope=active&page=3&search=prod');
    });
  });

  describe('search', () => {
    let searchBox;

    const waitForDebounce = async () => {
      await nextTick();
      jest.runOnlyPendingTimers();
    };

    beforeEach(async () => {
      await createWrapperWithMocked({
        environmentsApp: resolvedEnvironmentsApp,
        folder: resolvedFolder,
      });
      searchBox = wrapper.findComponent(GlSearchBoxByType);
    });

    it('should sync the query params to the new search', () => {
      searchBox.vm.$emit('input', 'hello');

      expect(window.location.search).toBe('?scope=active&page=1&search=hello');
    });

    it('should query for the entered parameter', async () => {
      const search = 'hello';

      searchBox.vm.$emit('input', search);

      await waitForDebounce();
      await waitForPromises();

      expect(environmentAppMock).toHaveBeenCalledWith(
        expect.anything(),
        expect.objectContaining({ search }),
        expect.anything(),
        expect.anything(),
      );
    });

    it('should sync search term from query params on load', () => {
      expect(searchBox.props('value')).toBe('prod');
    });
  });
});
