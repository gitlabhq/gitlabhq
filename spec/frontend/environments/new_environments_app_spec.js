import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { mount } from '@vue/test-utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
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

  const createWrapper = (apolloProvider) => mount(EnvironmentsApp, { apolloProvider });

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
    wrapper = createWrapper(apolloProvider);

    await waitForPromises();
    await Vue.nextTick();

    const text = wrapper.findAllComponents(EnvironmentsFolder).wrappers.map((w) => w.text());

    expect(text).toContainEqual(expect.stringMatching('review'));
    expect(text).not.toContainEqual(expect.stringMatching('production'));
  });
});
