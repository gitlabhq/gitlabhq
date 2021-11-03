import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { GlCollapse, GlIcon } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import EnvironmentsFolder from '~/environments/components/new_environment_folder.vue';
import { s__ } from '~/locale';
import { resolvedEnvironmentsApp, resolvedFolder } from './graphql/mock_data';

Vue.use(VueApollo);

describe('~/environments/components/new_environments_folder.vue', () => {
  let wrapper;
  let environmentFolderMock;
  let nestedEnvironment;
  let folderName;

  const findLink = () => wrapper.findByRole('link', { name: s__('Environments|Show all') });

  const createApolloProvider = () => {
    const mockResolvers = { Query: { folder: environmentFolderMock } };

    return createMockApollo([], mockResolvers);
  };

  const createWrapper = (propsData, apolloProvider) =>
    mountExtended(EnvironmentsFolder, { apolloProvider, propsData });

  beforeEach(() => {
    environmentFolderMock = jest.fn();
    [nestedEnvironment] = resolvedEnvironmentsApp.environments;
    environmentFolderMock.mockReturnValue(resolvedFolder);
    wrapper = createWrapper({ nestedEnvironment }, createApolloProvider());
    folderName = wrapper.findByText(nestedEnvironment.name);
  });

  afterEach(() => {
    wrapper?.destroy();
  });

  it('displays the name of the folder', () => {
    expect(folderName.text()).toBe(nestedEnvironment.name);
  });

  describe('collapse', () => {
    let icons;
    let collapse;

    beforeEach(() => {
      collapse = wrapper.findComponent(GlCollapse);
      icons = wrapper.findAllComponents(GlIcon);
    });

    it('is collapsed by default', () => {
      const link = findLink();

      expect(collapse.attributes('visible')).toBeUndefined();
      expect(icons.wrappers.map((i) => i.props('name'))).toEqual(['angle-right', 'folder-o']);
      expect(folderName.classes('gl-font-weight-bold')).toBe(false);
      expect(link.exists()).toBe(false);
    });

    it('opens on click', async () => {
      await folderName.trigger('click');

      const link = findLink();

      expect(collapse.attributes('visible')).toBe('true');
      expect(icons.wrappers.map((i) => i.props('name'))).toEqual(['angle-down', 'folder-open']);
      expect(folderName.classes('gl-font-weight-bold')).toBe(true);
      expect(link.attributes('href')).toBe(nestedEnvironment.latest.folderPath);
    });
  });
});
