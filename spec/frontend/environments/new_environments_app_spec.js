import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlPagination } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import setWindowLocation from 'helpers/set_window_location_helper';
import { sprintf, __, s__ } from '~/locale';
import EnvironmentsApp from '~/environments/components/new_environments_app.vue';
import EnvironmentsFolder from '~/environments/components/new_environment_folder.vue';
import EnvironmentsItem from '~/environments/components/new_environment_item.vue';
import StopEnvironmentModal from '~/environments/components/stop_environment_modal.vue';
import { resolvedEnvironmentsApp, resolvedFolder, resolvedEnvironment } from './graphql/mock_data';

Vue.use(VueApollo);

describe('~/environments/components/new_environments_app.vue', () => {
  let wrapper;
  let environmentAppMock;
  let environmentFolderMock;
  let paginationMock;
  let environmentToStopMock;

  const createApolloProvider = () => {
    const mockResolvers = {
      Query: {
        environmentApp: environmentAppMock,
        folder: environmentFolderMock,
        pageInfo: paginationMock,
        environmentToStop: environmentToStopMock,
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
        ...provide,
      },
      apolloProvider,
    });

  const createWrapperWithMocked = async ({
    provide = {},
    environmentsApp,
    folder,
    environmentToStop = {},
    pageInfo = {
      total: 20,
      perPage: 5,
      nextPage: 3,
      page: 2,
      previousPage: 1,
      __typename: 'LocalPageInfo',
    },
  }) => {
    setWindowLocation('?scope=available&page=2');
    environmentAppMock.mockReturnValue(environmentsApp);
    environmentFolderMock.mockReturnValue(folder);
    paginationMock.mockReturnValue(pageInfo);
    environmentToStopMock.mockReturnValue(environmentToStop);
    const apolloProvider = createApolloProvider();
    wrapper = createWrapper({ apolloProvider, provide });

    await waitForPromises();
    await nextTick();
  };

  beforeEach(() => {
    environmentAppMock = jest.fn();
    environmentFolderMock = jest.fn();
    environmentToStopMock = jest.fn();
    paginationMock = jest.fn();
  });

  afterEach(() => {
    wrapper?.destroy();
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

  it('should show a button to create a new environment', async () => {
    await createWrapperWithMocked({
      environmentsApp: resolvedEnvironmentsApp,
      folder: resolvedFolder,
    });

    const button = wrapper.findByRole('link', { name: s__('Environments|New environment') });
    expect(button.attributes('href')).toBe('/environments/new');
  });

  it('should not show a button to create a new environment if the user has no permissions', async () => {
    await createWrapperWithMocked({
      environmentsApp: resolvedEnvironmentsApp,
      folder: resolvedFolder,
      provide: { canCreateEnvironment: false, newEnvironmentPath: '' },
    });

    const button = wrapper.findByRole('link', { name: s__('Environments|New environment') });
    expect(button.exists()).toBe(false);
  });

  it('should show a button to open the review app modal', async () => {
    await createWrapperWithMocked({
      environmentsApp: resolvedEnvironmentsApp,
      folder: resolvedFolder,
    });

    const button = wrapper.findByRole('button', { name: s__('Environments|Enable review app') });
    button.trigger('click');

    await nextTick();

    expect(wrapper.findByText(s__('ReviewApp|Enable Review App')).exists()).toBe(true);
  });

  it('should not show a button to open the review app modal if review apps are configured', async () => {
    await createWrapperWithMocked({
      environmentsApp: {
        ...resolvedEnvironmentsApp,
        reviewApp: { canSetupReviewApp: false },
      },
      folder: resolvedFolder,
    });
    await waitForPromises();
    await nextTick();

    const button = wrapper.findByRole('button', { name: s__('Environments|Enable review app') });
    expect(button.exists()).toBe(false);
  });

  describe('tabs', () => {
    it('should show tabs for available and stopped environmets', async () => {
      await createWrapperWithMocked({
        environmentsApp: resolvedEnvironmentsApp,
        folder: resolvedFolder,
      });

      const [available, stopped] = wrapper.findAllByRole('tab').wrappers;

      expect(available.text()).toContain(__('Available'));
      expect(available.text()).toContain(resolvedEnvironmentsApp.availableCount);
      expect(stopped.text()).toContain(__('Stopped'));
      expect(stopped.text()).toContain(resolvedEnvironmentsApp.stoppedCount);
    });

    it('should change the requested scope on tab change', async () => {
      await createWrapperWithMocked({
        environmentsApp: resolvedEnvironmentsApp,
        folder: resolvedFolder,
      });
      const stopped = wrapper.findByRole('tab', {
        name: `${__('Stopped')} ${resolvedEnvironmentsApp.stoppedCount}`,
      });

      stopped.trigger('click');

      await nextTick();
      await waitForPromises();

      expect(environmentAppMock).toHaveBeenCalledWith(
        expect.anything(),
        expect.objectContaining({ scope: 'stopped' }),
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
        name: __('Go to next page'),
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
        name: __('Go to previous page'),
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
        name: sprintf(__('Go to page %{page}'), { page }),
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
        name: __('Go to next page'),
      });

      next.trigger('click');

      await nextTick();
      expect(window.location.search).toBe('?scope=available&page=3');
    });
  });
});
