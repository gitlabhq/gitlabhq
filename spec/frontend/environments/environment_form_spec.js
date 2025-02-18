import { GlLoadingIcon } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import waitForPromises from 'helpers/wait_for_promises';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import EnvironmentForm from '~/environments/components/environment_form.vue';
import getUserAuthorizedAgents from '~/environments/graphql/queries/user_authorized_agents.query.graphql';
import EnvironmentFluxResourceSelector from '~/environments/components/environment_flux_resource_selector.vue';
import EnvironmentNamespaceSelector from '~/environments/components/environment_namespace_selector.vue';
import createMockApollo from '../__helpers__/mock_apollo_helper';
import { mockKasTunnelUrl } from './mock_data';

jest.mock('~/lib/utils/csrf');

const DEFAULT_PROPS = {
  environment: { name: '', externalUrl: '', description: '' },
  title: 'environment',
  cancelPath: '/cancel',
};

const PROVIDE = {
  protectedEnvironmentSettingsPath: '/projects/not_real/settings/ci_cd',
  kasTunnelUrl: mockKasTunnelUrl,
  markdownPreviewPath: '/path/to/markdown/preview',
};
const userAccessAuthorizedAgents = [
  { agent: { id: '1', name: 'agent-1' } },
  { agent: { id: '2', name: 'agent-2' } },
];

const configuration = {
  basePath: mockKasTunnelUrl.replace(/\/$/, ''),
  headers: {
    'GitLab-Agent-Id': 2,
    'Content-Type': 'application/json',
    Accept: 'application/json',
  },
  credentials: 'include',
};

const environmentWithAgentAndNamespace = {
  ...DEFAULT_PROPS.environment,
  clusterAgent: { id: '12', name: 'agent-2' },
  clusterAgentId: '2',
  kubernetesNamespace: 'agent',
};

describe('~/environments/components/form.vue', () => {
  let wrapper;

  const createWrapper = (propsData = {}, options = {}) =>
    mountExtended(EnvironmentForm, {
      provide: PROVIDE,
      ...options,
      propsData: {
        ...DEFAULT_PROPS,
        ...propsData,
      },
    });

  const createWrapperWithApollo = (propsData = {}) => {
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

    return mountExtended(EnvironmentForm, {
      provide: {
        ...PROVIDE,
      },
      propsData: {
        ...DEFAULT_PROPS,
        ...propsData,
      },
      apolloProvider: createMockApollo(requestHandlers, []),
    });
  };

  const findAgentSelector = () => wrapper.findByTestId('agent-selector');
  const findNamespaceSelector = () => wrapper.findComponent(EnvironmentNamespaceSelector);
  const findFluxResourceSelector = () => wrapper.findComponent(EnvironmentFluxResourceSelector);
  const findMarkdownField = () => wrapper.findComponent(MarkdownEditor);

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
      expect(link.attributes('href')).toBe('/help/ci/environments/_index.md');
    });

    it('links to documentation regarding granting kubernetes access', () => {
      const link = wrapper.findByRole('link', { name: 'How do I grant Kubernetes access?' });
      expect(link.attributes('href')).toBe('/help/user/clusters/agent/user_access.md');
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

        expect(wrapper.emitted('change')).toEqual([
          [{ name: 'test', externalUrl: '', description: '' }],
        ]);
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
          [{ name: '', externalUrl: 'https://example.com', description: '' }],
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
          description: '',
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
          description: '',
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

  describe('description', () => {
    it('renders markdown field', () => {
      wrapper = createWrapper();

      expect(findMarkdownField().props()).toMatchObject({
        value: '',
        renderMarkdownPath: PROVIDE.markdownPreviewPath,
        markdownDocsPath: '/help/user/markdown',
        disabled: false,
      });
    });

    it('sets the markdown value when provided', () => {
      wrapper = createWrapper({
        environment: { name: 'production', externalUrl: '', description: 'some-description' },
      });

      expect(findMarkdownField().props('value')).toBe('some-description');
    });

    it('emits changes on user input', async () => {
      wrapper = createWrapper();
      await findMarkdownField().vm.$emit('input', 'my new description');

      expect(wrapper.emitted('change').at(-1)).toEqual([
        { name: '', externalUrl: '', description: 'my new description' },
      ]);
    });

    it('disables field on loading', () => {
      wrapper = createWrapper({ loading: true });

      expect(findMarkdownField().props('disabled')).toBe(true);
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
            description: '',
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

      it('emits changes to the kubernetesNamespace', async () => {
        await waitForPromises();
        findNamespaceSelector().vm.$emit('change', 'agent');
        await nextTick();

        expect(wrapper.emitted('change')[1]).toEqual([
          {
            name: '',
            externalUrl: '',
            description: '',
            kubernetesNamespace: 'agent',
            fluxResourcePath: null,
          },
        ]);
      });
    });
  });

  describe('flux resource selector', () => {
    beforeEach(() => {
      wrapper = createWrapperWithApollo();
    });

    it("doesn't render flux resource selector by default", () => {
      expect(findFluxResourceSelector().exists()).toBe(false);
    });

    describe('when the agent was selected', () => {
      beforeEach(async () => {
        await selectAgent();
      });

      it('renders flux resource selector', () => {
        expect(findFluxResourceSelector().exists()).toBe(true);
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
      wrapper = createWrapperWithApollo({ environment: environmentWithAgent });
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

      expect(findNamespaceSelector().exists()).toBe(true);
    });
  });

  describe('when environment has an associated kubernetes namespace', () => {
    beforeEach(() => {
      wrapper = createWrapperWithApollo({ environment: environmentWithAgentAndNamespace });
    });

    it('updates namespace selector with the name of the associated namespace', async () => {
      await waitForPromises();
      expect(findNamespaceSelector().props('namespace')).toBe('agent');
    });

    it('clears namespace selector when another agent was selected', async () => {
      expect(findNamespaceSelector().props('namespace')).toBe('agent');

      findAgentSelector().vm.$emit('select', '1');
      await nextTick();

      expect(findNamespaceSelector().props('namespace')).toBe(null);
    });

    it('renders the flux resource selector when the namespace is selected', () => {
      expect(findFluxResourceSelector().props()).toEqual({
        namespace: 'agent',
        fluxResourcePath: '',
        configuration,
      });
    });
  });

  describe('when environment has an associated flux resource', () => {
    const fluxResourcePath = 'path/to/flux/resource';
    const environmentWithFluxResource = {
      ...environmentWithAgentAndNamespace,
      fluxResourcePath,
    };
    beforeEach(() => {
      wrapper = createWrapperWithApollo({ environment: environmentWithFluxResource });
    });

    it('provides flux resource path to the flux resource selector component', () => {
      expect(findFluxResourceSelector().props('fluxResourcePath')).toBe(fluxResourcePath);
    });
  });
});
