import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { __, s__ } from '~/locale';
import EnvironmentsApp from '~/environments/components/new_environments_app.vue';
import EnvironmentsFolder from '~/environments/components/new_environment_folder.vue';
import { resolvedEnvironmentsApp, resolvedFolder } from './graphql/mock_data';

Vue.use(VueApollo);

describe('~/environments/components/new_environments_app.vue', () => {
  let wrapper;
  let environmentAppMock;
  let environmentFolderMock;

  const createApolloProvider = () => {
    const mockResolvers = {
      Query: {
        environmentApp: environmentAppMock,
        folder: environmentFolderMock,
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

  const createWrapperWithMocked = async ({ provide = {}, environmentsApp, folder }) => {
    environmentAppMock.mockReturnValue(environmentsApp);
    environmentFolderMock.mockReturnValue(folder);
    const apolloProvider = createApolloProvider();
    wrapper = createWrapper({ apolloProvider, provide });

    await waitForPromises();
    await nextTick();
  };

  beforeEach(() => {
    environmentAppMock = jest.fn();
    environmentFolderMock = jest.fn();
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
    environmentAppMock.mockReturnValue(resolvedEnvironmentsApp);
    environmentFolderMock.mockReturnValue(resolvedFolder);
    const apolloProvider = createApolloProvider();
    wrapper = createWrapper({ apolloProvider });

    await waitForPromises();
    await nextTick();
    const stopped = wrapper.findByRole('tab', {
      name: `${__('Stopped')} ${resolvedEnvironmentsApp.stoppedCount}`,
    });

    stopped.trigger('click');

    await nextTick();
    await waitForPromises();

    expect(environmentAppMock).toHaveBeenCalledWith(
      expect.anything(),
      { scope: 'stopped' },
      expect.anything(),
      expect.anything(),
    );
  });
});
