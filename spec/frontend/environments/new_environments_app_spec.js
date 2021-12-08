import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { s__ } from '~/locale';
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
      Query: { environmentApp: environmentAppMock, folder: environmentFolderMock },
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

  beforeEach(() => {
    environmentAppMock = jest.fn();
    environmentFolderMock = jest.fn();
  });

  afterEach(() => {
    wrapper?.destroy();
  });

  it('should show all the folders that are fetched', async () => {
    environmentAppMock.mockReturnValue(resolvedEnvironmentsApp);
    environmentFolderMock.mockReturnValue(resolvedFolder);
    const apolloProvider = createApolloProvider();
    wrapper = createWrapper({ apolloProvider });

    await waitForPromises();
    await Vue.nextTick();

    const text = wrapper.findAllComponents(EnvironmentsFolder).wrappers.map((w) => w.text());

    expect(text).toContainEqual(expect.stringMatching('review'));
    expect(text).not.toContainEqual(expect.stringMatching('production'));
  });

  it('should show a button to create a new environment', async () => {
    environmentAppMock.mockReturnValue(resolvedEnvironmentsApp);
    environmentFolderMock.mockReturnValue(resolvedFolder);
    const apolloProvider = createApolloProvider();
    wrapper = createWrapper({ apolloProvider });

    await waitForPromises();
    await Vue.nextTick();

    const button = wrapper.findByRole('link', { name: s__('Environments|New environment') });
    expect(button.attributes('href')).toBe('/environments/new');
  });

  it('should not show a button to create a new environment if the user has no permissions', async () => {
    environmentAppMock.mockReturnValue(resolvedEnvironmentsApp);
    environmentFolderMock.mockReturnValue(resolvedFolder);
    const apolloProvider = createApolloProvider();
    wrapper = createWrapper({
      apolloProvider,
      provide: { canCreateEnvironment: false, newEnvironmentPath: '' },
    });

    await waitForPromises();
    await Vue.nextTick();

    const button = wrapper.findByRole('link', { name: s__('Environments|New environment') });
    expect(button.exists()).toBe(false);
  });

  it('should show a button to open the review app modal', async () => {
    environmentAppMock.mockReturnValue(resolvedEnvironmentsApp);
    environmentFolderMock.mockReturnValue(resolvedFolder);
    const apolloProvider = createApolloProvider();
    wrapper = createWrapper({ apolloProvider });

    await waitForPromises();
    await Vue.nextTick();

    const button = wrapper.findByRole('button', { name: s__('Environments|Enable review app') });
    button.trigger('click');

    await Vue.nextTick();

    expect(wrapper.findByText(s__('ReviewApp|Enable Review App')).exists()).toBe(true);
  });

  it('should not show a button to open the review app modal if review apps are configured', async () => {
    environmentAppMock.mockReturnValue({
      ...resolvedEnvironmentsApp,
      reviewApp: { canSetupReviewApp: false },
    });
    environmentFolderMock.mockReturnValue(resolvedFolder);
    const apolloProvider = createApolloProvider();
    wrapper = createWrapper({ apolloProvider });

    await waitForPromises();
    await Vue.nextTick();

    const button = wrapper.findByRole('button', { name: s__('Environments|Enable review app') });
    expect(button.exists()).toBe(false);
  });
});
