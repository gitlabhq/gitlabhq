import { GlLoadingIcon, GlAlert } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import waitForPromises from 'helpers/wait_for_promises';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import EnvironmentForm from '~/environments/components/environment_form.vue';
import getUserAuthorizedAgents from '~/environments/graphql/queries/user_authorized_agents.query.graphql';
import EnvironmentFluxResourceSelector from '~/environments/components/environment_flux_resource_selector.vue';
import createMockApollo from '../__helpers__/mock_apollo_helper';
import { mockKasTunnelUrl } from './mock_data';

jest.mock('~/lib/utils/csrf');

const DEFAULT_PROPS = {
  environment: { name: '', externalUrl: '' },
  title: 'environment',
  cancelPath: '/cancel',
};

const PROVIDE = {
  protectedEnvironmentSettingsPath: '/projects/not_real/settings/ci_cd',
  kasTunnelUrl: mockKasTunnelUrl,
};
const userAccessAuthorizedAgents = [
  { agent: { id: '1', name: 'agent-1' } },
  { agent: { id: '2', name: 'agent-2' } },
];

const configuration = {
  basePath: mockKasTunnelUrl.replace(/\/$/, ''),
  baseOptions: {
    headers: {
      'GitLab-Agent-Id': 2,
    },
    withCredentials: true,
  },
};

describe('~/environments/components/form.vue', () => {
  let wrapper;

  const getNamespacesQueryResult = jest
    .fn()
    .mockReturnValue([{ metadata: { name: 'default' } }, { metadata: { name: 'agent' } }]);

  const createWrapper = (propsData = {}, options = {}) =>
    mountExtended(EnvironmentForm, {
      provide: PROVIDE,
      ...options,
      propsData: {
        ...DEFAULT_PROPS,
        ...propsData,
      },
    });

  const createWrapperWithApollo = ({
    propsData = {},
    fluxResourceForEnvironment = false,
    queryResult = null,
  } = {}) => {
    Vue.use(VueApollo);

    const requestHandlers = [
      [
        getUserAuthorizedAgents,
        jest.fn().mockResolvedValue({
          data: {
            project: {
              id: '1',
              userAccessAuthorizedAgents: { nodes: userAccessAuthorizedAgents },
            },
          },
        }),
      ],
    ];

    const mockResolvers = {
      Query: {
        k8sNamespaces: queryResult || getNamespacesQueryResult,
      },
    };

    return mountExtended(EnvironmentForm, {
      provide: {
        ...PROVIDE,
        glFeatures: {
          fluxResourceForEnvironment,
        },
      },
      propsData: {
        ...DEFAULT_PROPS,
        ...propsData,
      },
      apolloProvider: createMockApollo(requestHandlers, mockResolvers),
    });
  };

  const findAgentSelector = () => wrapper.findByTestId('agent-selector');
  const findNamespaceSelector = () => wrapper.findByTestId('namespace-selector');
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findFluxResourceSelector = () => wrapper.findComponent(EnvironmentFluxResourceSelector);

  const selectAgent = async () => {
    findAgentSelector().vm.$emit('shown');
    await waitForPromises();
    await findAgentSelector().vm.$emit('select', '2');
  };

  describe('default', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('links to documentation regarding environments', () => {
      const link = wrapper.findByRole('link', { name: 'More information.' });
      expect(link.attributes('href')).toBe('/help/ci/environments/index.md');
    });

    it('links the cancel button to the cancel path', () => {
      const cancel = wrapper.findByRole('link', { name: 'Cancel' });

      expect(cancel.attributes('href')).toBe(DEFAULT_PROPS.cancelPath);
    });

    describe('name input', () => {
      let name;

      beforeEach(() => {
        name = wrapper.findByLabelText('Name');
      });

      it('should emit changes to the name', async () => {
        await name.setValue('test');
        await name.trigger('blur');

        expect(wrapper.emitted('change')).toEqual([[{ name: 'test', externalUrl: '' }]]);
      });

      it('should validate that the name is required', async () => {
        await name.setValue('');
        await name.trigger('blur');

        expect(wrapper.findByText('This field is required').exists()).toBe(true);
        expect(name.attributes('aria-invalid')).toBe('true');
      });
    });

    describe('url input', () => {
      let url;

      beforeEach(() => {
        url = wrapper.findByLabelText('External URL');
      });

      it('should emit changes to the url', async () => {
        await url.setValue('https://example.com');
        await url.trigger('blur');

        expect(wrapper.emitted('change')).toEqual([
          [{ name: '', externalUrl: 'https://example.com' }],
        ]);
      });

      it('should validate that the url is required', async () => {
        await url.setValue('example.com');
        await url.trigger('blur');

        expect(wrapper.findByText('The URL should start with http:// or https://').exists()).toBe(
          true,
        );
        expect(url.attributes('aria-invalid')).toBe('true');
      });
    });

    it('submits when the form does', async () => {
      await wrapper.findByRole('form', { title: 'environment' }).trigger('submit');

      expect(wrapper.emitted('submit')).toEqual([[]]);
    });
  });

  it('shows a loading icon while loading', () => {
    wrapper = createWrapper({ loading: true });
    expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
  });

  describe('when a new environment is being created', () => {
    beforeEach(() => {
      wrapper = createWrapper({
        environment: {
          name: '',
          externalUrl: '',
        },
      });
    });

    it('renders an enabled "Name" field', () => {
      const nameInput = wrapper.findByLabelText('Name');

      expect(nameInput.attributes().disabled).toBeUndefined();
      expect(nameInput.element.value).toBe('');
    });

    it('renders an "External URL" field', () => {
      const urlInput = wrapper.findByLabelText('External URL');

      expect(urlInput.element.value).toBe('');
    });

    it('does not show protected environment documentation', () => {
      expect(wrapper.findByRole('link', { name: 'Protected environments' }).exists()).toBe(false);
    });
  });

  describe('when no protected environment link is provided', () => {
    beforeEach(() => {
      wrapper = createWrapper({
        provide: {},
      });
    });

    it('does not show protected environment documentation', () => {
      expect(wrapper.findByRole('link', { name: 'Protected environments' }).exists()).toBe(false);
    });
  });

  describe('when an existing environment is being edited', () => {
    beforeEach(() => {
      wrapper = createWrapper({
        environment: {
          id: 1,
          name: 'test',
          externalUrl: 'https://example.com',
        },
      });
    });

    it('renders a disabled "Name" field', () => {
      const nameInput = wrapper.findByLabelText('Name');

      expect(nameInput.attributes().disabled).toBe('disabled');
      expect(nameInput.element.value).toBe('test');
    });

    it('renders an "External URL" field', () => {
      const urlInput = wrapper.findByLabelText('External URL');

      expect(urlInput.element.value).toBe('https://example.com');
    });

    it('renders an agent selector listbox', () => {
      expect(findAgentSelector().props()).toMatchObject({
        searchable: true,
        toggleText: EnvironmentForm.i18n.agentHelpText,
        headerText: EnvironmentForm.i18n.agentHelpText,
        resetButtonLabel: EnvironmentForm.i18n.reset,
        loading: false,
        items: [],
      });
    });
  });

  describe('agent selector', () => {
    beforeEach(() => {
      wrapper = createWrapperWithApollo();
    });

    it('sets the items prop of the agent selector after fetching the list', async () => {
      findAgentSelector().vm.$emit('shown');
      await waitForPromises();

      expect(findAgentSelector().props('items')).toEqual([
        { value: '1', text: 'agent-1' },
        { value: '2', text: 'agent-2' },
      ]);
    });

    it('sets the loading prop of the agent selector while fetching the list', async () => {
      await findAgentSelector().vm.$emit('shown');
      expect(findAgentSelector().props('loading')).toBe(true);

      await waitForPromises();

      expect(findAgentSelector().props('loading')).toBe(false);
    });

    it('filters the agent list on user search', async () => {
      findAgentSelector().vm.$emit('shown');
      await waitForPromises();
      await findAgentSelector().vm.$emit('search', 'agent-2');

      expect(findAgentSelector().props('items')).toEqual([{ value: '2', text: 'agent-2' }]);
    });

    it('updates agent selector field with the name of selected agent', async () => {
      await selectAgent();

      expect(findAgentSelector().props('toggleText')).toBe('agent-2');
    });

    it('emits changes to the clusterAgentId', async () => {
      await selectAgent();

      expect(wrapper.emitted('change')).toEqual([
        [
          {
            name: '',
            externalUrl: '',
            clusterAgentId: '2',
            kubernetesNamespace: null,
            fluxResourcePath: null,
          },
        ],
      ]);
    });
  });

  describe('namespace selector', () => {
    beforeEach(() => {
      wrapper = createWrapperWithApollo();
    });

    it("doesn't render namespace selector by default", () => {
      expect(findNamespaceSelector().exists()).toBe(false);
    });

    describe('when the agent was selected', () => {
      beforeEach(async () => {
        await selectAgent();
      });

      it('renders namespace selector', () => {
        expect(findNamespaceSelector().exists()).toBe(true);
      });

      it('requests the kubernetes namespaces with the correct configuration', async () => {
        await waitForPromises();

        expect(getNamespacesQueryResult).toHaveBeenCalledWith(
          {},
          { configuration },
          expect.anything(),
          expect.anything(),
        );
      });

      it('sets the loading prop while fetching the list', async () => {
        expect(findNamespaceSelector().props('loading')).toBe(true);

        await waitForPromises();

        expect(findNamespaceSelector().props('loading')).toBe(false);
      });

      it('renders a list of available namespaces', async () => {
        await waitForPromises();

        expect(findNamespaceSelector().props('items')).toEqual([
          { text: 'default', value: 'default' },
          { text: 'agent', value: 'agent' },
        ]);
      });

      it('filters the namespaces list on user search', async () => {
        await waitForPromises();
        await findNamespaceSelector().vm.$emit('search', 'default');

        expect(findNamespaceSelector().props('items')).toEqual([
          { value: 'default', text: 'default' },
        ]);
      });

      it('updates namespace selector field with the name of selected namespace', async () => {
        await waitForPromises();
        await findNamespaceSelector().vm.$emit('select', 'agent');

        expect(findNamespaceSelector().props('toggleText')).toBe('agent');
      });

      it('emits changes to the kubernetesNamespace', async () => {
        await waitForPromises();
        await findNamespaceSelector().vm.$emit('select', 'agent');

        expect(wrapper.emitted('change')[1]).toEqual([
          { name: '', externalUrl: '', kubernetesNamespace: 'agent', fluxResourcePath: null },
        ]);
      });

      it('clears namespace selector when another agent was selected', async () => {
        await waitForPromises();
        await findNamespaceSelector().vm.$emit('select', 'agent');

        expect(findNamespaceSelector().props('toggleText')).toBe('agent');

        await findAgentSelector().vm.$emit('select', '1');
        expect(findNamespaceSelector().props('toggleText')).toBe(
          EnvironmentForm.i18n.namespaceHelpText,
        );
      });
    });

    describe('when cannot connect to the cluster', () => {
      const error = new Error('Error from the cluster_client API');

      beforeEach(async () => {
        wrapper = createWrapperWithApollo({
          queryResult: jest.fn().mockRejectedValueOnce(error),
        });

        await selectAgent();
        await waitForPromises();
      });

      it("doesn't render the namespace selector", () => {
        expect(findNamespaceSelector().exists()).toBe(false);
      });

      it('renders an alert', () => {
        expect(findAlert().text()).toBe('Error from the cluster_client API');
      });
    });
  });

  describe('flux resource selector', () => {
    it("doesn't render if `fluxResourceForEnvironment` feature flag is disabled", () => {
      wrapper = createWrapperWithApollo();
      expect(findFluxResourceSelector().exists()).toBe(false);
    });

    describe('when `fluxResourceForEnvironment` feature flag is enabled', () => {
      beforeEach(() => {
        wrapper = createWrapperWithApollo({
          fluxResourceForEnvironment: true,
        });
      });

      it("doesn't render flux resource selector by default", () => {
        expect(findFluxResourceSelector().exists()).toBe(false);
      });

      describe('when the agent was selected', () => {
        beforeEach(async () => {
          await selectAgent();
        });

        it("doesn't render flux resource selector", () => {
          expect(findFluxResourceSelector().exists()).toBe(false);
        });

        it('renders the flux resource selector when the namespace is selected', async () => {
          await findNamespaceSelector().vm.$emit('select', 'agent');

          expect(findFluxResourceSelector().props()).toEqual({
            namespace: 'agent',
            fluxResourcePath: '',
            configuration,
          });
        });
      });
    });
  });

  describe('when environment has an associated agent', () => {
    const environmentWithAgent = {
      ...DEFAULT_PROPS.environment,
      clusterAgent: { id: '1', name: 'agent-1' },
      clusterAgentId: '1',
    };
    beforeEach(() => {
      wrapper = createWrapperWithApollo({
        propsData: { environment: environmentWithAgent },
      });
    });

    it('updates agent selector field with the name of the associated agent', () => {
      expect(findAgentSelector().props('toggleText')).toBe('agent-1');
    });

    it('renders namespace selector', async () => {
      await waitForPromises();
      expect(findNamespaceSelector().exists()).toBe(true);
    });

    it('renders a list of available namespaces', async () => {
      await waitForPromises();

      expect(findNamespaceSelector().props('items')).toEqual([
        { text: 'default', value: 'default' },
        { text: 'agent', value: 'agent' },
      ]);
    });
  });

  describe('when environment has an associated kubernetes namespace', () => {
    const environmentWithAgentAndNamespace = {
      ...DEFAULT_PROPS.environment,
      clusterAgent: { id: '1', name: 'agent-1' },
      clusterAgentId: '1',
      kubernetesNamespace: 'default',
    };
    beforeEach(() => {
      wrapper = createWrapperWithApollo({
        propsData: { environment: environmentWithAgentAndNamespace },
      });
    });

    it('updates namespace selector with the name of the associated namespace', async () => {
      await waitForPromises();
      expect(findNamespaceSelector().props('toggleText')).toBe('default');
    });
  });

  describe('when environment has an associated flux resource', () => {
    const fluxResourcePath = 'path/to/flux/resource';
    const environmentWithAgentAndNamespace = {
      ...DEFAULT_PROPS.environment,
      clusterAgent: { id: '1', name: 'agent-1' },
      clusterAgentId: '1',
      kubernetesNamespace: 'default',
      fluxResourcePath,
    };
    beforeEach(() => {
      wrapper = createWrapperWithApollo({
        propsData: { environment: environmentWithAgentAndNamespace },
        fluxResourceForEnvironment: true,
      });
    });

    it('provides flux resource path to the flux resource selector component', () => {
      expect(findFluxResourceSelector().props('fluxResourcePath')).toBe(fluxResourcePath);
    });
  });
});
