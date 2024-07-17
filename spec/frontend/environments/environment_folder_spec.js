import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';
import { GlCollapse, GlIcon } from '@gitlab/ui';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { stubTransition } from 'helpers/stub_transition';
import { __, s__, sprintf } from '~/locale';
import EnvironmentsFolder from '~/environments/components/environment_folder.vue';
import EnvironmentItem from '~/environments/components/new_environment_item.vue';
import { resolvedEnvironmentsApp, resolvedFolder } from './graphql/mock_data';

Vue.use(VueApollo);

describe('~/environments/components/environments_folder.vue', () => {
  let wrapper;
  let environmentFolderMock;
  let intervalMock;
  let nestedEnvironment;

  const findLink = () => wrapper.findByText(s__('Environments|See all environments.'));
  const findMessage = () =>
    wrapper.findByText(
      sprintf(
        s__(
          'Environments|Showing %{listedEnvironmentsCount} of %{totalEnvironmentsCount} environments in this folder.',
        ),
        { listedEnvironmentsCount: 2, totalEnvironmentsCount: 4 },
      ),
    );
  const findFolderMessageElement = () => wrapper.findByTestId('environment-folder-message-element');

  const createApolloProvider = () => {
    const mockResolvers = { Query: { folder: environmentFolderMock, interval: intervalMock } };

    return createMockApollo([], mockResolvers);
  };

  const createWrapper = (propsData, apolloProvider) =>
    mountExtended(EnvironmentsFolder, {
      apolloProvider,
      propsData: {
        scope: 'available',
        search: '',
        ...propsData,
      },
      stubs: { transition: stubTransition() },
      provide: { helpPagePath: '/help', projectId: '1', projectPath: 'path/to/project' },
    });

  beforeEach(() => {
    environmentFolderMock = jest.fn();
    [nestedEnvironment] = resolvedEnvironmentsApp.environments;
    environmentFolderMock.mockReturnValue(resolvedFolder);
    intervalMock = jest.fn();
    intervalMock.mockReturnValue(2000);
  });

  afterEach(() => {
    wrapper?.destroy();
  });

  describe('default', () => {
    let folderName;
    let button;

    beforeEach(async () => {
      wrapper = createWrapper({ nestedEnvironment }, createApolloProvider());

      await nextTick();
      await waitForPromises();
      folderName = wrapper.findByText(nestedEnvironment.name);
      button = wrapper.findByRole('button', { name: __('Expand') });
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
        expect(collapse.props('visible')).toBe(false);
        const iconNames = icons.wrappers.map((i) => i.props('name')).slice(0, 2);
        expect(iconNames).toEqual(['chevron-lg-right', 'folder']);
        expect(folderName.classes('gl-font-bold')).toBe(false);
      });

      it('opens on click and starts polling', async () => {
        expect(environmentFolderMock).toHaveBeenCalledTimes(1);

        await button.trigger('click');
        jest.advanceTimersByTime(2000);
        await waitForPromises();

        expect(button.attributes('aria-label')).toBe(__('Collapse'));
        expect(collapse.props('visible')).toBe(true);
        const iconNames = icons.wrappers.map((i) => i.props('name')).slice(0, 2);
        expect(iconNames).toEqual(['chevron-lg-down', 'folder-open']);
        expect(folderName.classes('gl-font-bold')).toBe(true);

        expect(environmentFolderMock).toHaveBeenCalledTimes(2);
      });

      it('displays all environments when opened', async () => {
        await button.trigger('click');

        const names = resolvedFolder.environments.map((e) =>
          expect.stringMatching(e.nameWithoutType),
        );
        const environments = wrapper
          .findAllComponents(EnvironmentItem)
          .wrappers.map((w) => w.text());
        expect(environments).toEqual(expect.arrayContaining(names));
      });

      it('stops polling on click', async () => {
        await button.trigger('click');
        jest.advanceTimersByTime(2000);
        await waitForPromises();

        expect(environmentFolderMock).toHaveBeenCalledTimes(2);

        const collapseButton = wrapper.findByRole('button', { name: __('Collapse') });
        await collapseButton.trigger('click');

        expect(environmentFolderMock).toHaveBeenCalledTimes(2);
      });

      describe('when there are more environments to show inside the folder', () => {
        it('displays the message with the correct text and a link to navigate to all environments', async () => {
          environmentFolderMock.mockReturnValue({ ...resolvedFolder, activeCount: 4 });
          wrapper = createWrapper({ scope: 'active', nestedEnvironment }, createApolloProvider());

          await nextTick();
          await waitForPromises();

          const link = findLink();
          const message = findMessage();
          const element = findFolderMessageElement();

          expect(element.exists()).toBe(true);
          expect(link.attributes('href')).toBe(nestedEnvironment.latest.folderPath);
          expect(message.exists()).toBe(true);
        });
      });

      describe('when all available environments inside the folder are shown', () => {
        it("doesn't display the message and a link", () => {
          const link = findLink();
          const message = findMessage();
          const element = findFolderMessageElement();

          expect(element.exists()).toBe(false);
          expect(link.exists()).toBe(false);
          expect(message.exists()).toBe(false);
        });
      });
    });
  });

  it.each(['available', 'stopped'])(
    'with scope=%s, fetches environments with scope',
    async (scope) => {
      wrapper = createWrapper({ nestedEnvironment, scope }, createApolloProvider());

      await nextTick();
      await waitForPromises();

      expect(environmentFolderMock).toHaveBeenCalledTimes(1);
      expect(environmentFolderMock).toHaveBeenCalledWith(
        {},
        expect.objectContaining({ scope }),
        expect.anything(),
        expect.anything(),
      );
    },
  );

  it('should query for the entered parameter', async () => {
    const search = 'hello';

    wrapper = createWrapper({ nestedEnvironment, search }, createApolloProvider());

    await nextTick();
    await waitForPromises();

    expect(environmentFolderMock).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining({ search }),
      expect.anything(),
      expect.anything(),
    );
  });
});
