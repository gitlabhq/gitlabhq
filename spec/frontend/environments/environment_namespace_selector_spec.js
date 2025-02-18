import {
  GlAlert,
  GlCollapsibleListbox,
  GlButton,
  GlFormGroup,
  GlSprintf,
  GlLink,
} from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import EnvironmentNamespaceSelector from '~/environments/components/environment_namespace_selector.vue';
import { stubComponent } from 'helpers/stub_component';
import createMockApollo from '../__helpers__/mock_apollo_helper';
import { mockKasTunnelUrl } from './mock_data';

const configuration = {
  basePath: mockKasTunnelUrl.replace(/\/$/, ''),
  headers: {
    'GitLab-Agent-Id': 2,
    'Content-Type': 'application/json',
    Accept: 'application/json',
  },
  credentials: 'include',
};

const DEFAULT_PROPS = {
  namespace: '',
  configuration,
};

describe('~/environments/components/namespace_selector.vue', () => {
  let wrapper;

  const getNamespacesQueryResult = jest
    .fn()
    .mockReturnValue([
      { metadata: { name: 'default' } },
      { metadata: { name: 'agent' } },
      { metadata: { name: 'test-agent' } },
    ]);

  const closeMock = jest.fn();

  const createWrapper = ({ propsData = {}, queryResult = null, stubs = {} } = {}) => {
    Vue.use(VueApollo);

    const mockResolvers = {
      Query: {
        k8sNamespaces: queryResult || getNamespacesQueryResult,
      },
    };

    return shallowMount(EnvironmentNamespaceSelector, {
      propsData: {
        ...DEFAULT_PROPS,
        ...propsData,
      },
      stubs: {
        GlCollapsibleListbox: stubComponent(GlCollapsibleListbox, {
          template: `<div><slot name="footer"></slot></div>`,
          methods: {
            close: closeMock,
          },
        }),
        ...stubs,
      },
      apolloProvider: createMockApollo([], mockResolvers),
    });
  };

  const findNamespaceSelector = () => wrapper.findComponent(GlCollapsibleListbox);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findSelectButton = () => wrapper.findComponent(GlButton);

  const searchNamespace = async (searchTerm = 'test') => {
    findNamespaceSelector().vm.$emit('search', searchTerm);
    await nextTick();
  };

  describe('default', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('renders namespace selector', () => {
      expect(findNamespaceSelector().exists()).toBe(true);
    });

    it('requests the namespaces', async () => {
      await waitForPromises();

      expect(getNamespacesQueryResult).toHaveBeenCalled();
    });

    it('sets the loading prop while fetching the list', async () => {
      expect(findNamespaceSelector().props('loading')).toBe(true);

      await waitForPromises();

      expect(findNamespaceSelector().props('loading')).toBe(false);
    });

    it('renders a list of available namespaces', async () => {
      await waitForPromises();

      expect(findNamespaceSelector().props('items')).toMatchObject([
        {
          text: 'default',
          value: 'default',
        },
        {
          text: 'agent',
          value: 'agent',
        },
        {
          text: 'test-agent',
          value: 'test-agent',
        },
      ]);
    });

    it('renders description', () => {
      wrapper = createWrapper({
        stubs: {
          GlFormGroup: stubComponent(GlFormGroup, {
            template: `<div><slot name="description"></slot></div>`,
          }),
          GlSprintf,
        },
      });
      const link = wrapper.findComponent(GlLink);

      expect(wrapper.text()).toBe(
        'No selection shows all authorized resources in the cluster. Learn more.',
      );
      expect(link.attributes('target')).toBe('_blank');
      expect(link.attributes('href')).toBe('/help/user/clusters/agent/_index.md');
      expect(link.text()).toBe('Learn more.');
    });

    it('filters the namespaces list on user search', async () => {
      await waitForPromises();
      await searchNamespace('agent');

      expect(findNamespaceSelector().props('items')).toMatchObject([
        {
          text: 'agent',
          value: 'agent',
        },
        {
          text: 'test-agent',
          value: 'test-agent',
        },
      ]);
    });

    it('emits changes to the namespace', () => {
      findNamespaceSelector().vm.$emit('select', 'agent');

      expect(wrapper.emitted('change')).toEqual([['agent']]);
    });

    it('emits `null` to the namespace on reset', () => {
      findNamespaceSelector().vm.$emit('reset');

      expect(wrapper.emitted('change')).toEqual([[null]]);
    });
  });

  describe('custom select button', () => {
    beforeEach(async () => {
      wrapper = createWrapper();
      await waitForPromises();
    });

    it("doesn't render custom select button before searching", () => {
      expect(findSelectButton().exists()).toBe(false);
    });

    it("doesn't render custom select button when the search is found in the namespaces list", async () => {
      await searchNamespace('test-agent');
      expect(findSelectButton().exists()).toBe(false);
    });

    it('renders custom select button when the namespace searched for is not found in the namespaces list', async () => {
      await searchNamespace();
      expect(findSelectButton().exists()).toBe(true);
    });

    it('emits custom filled namespace name to the `change` event', async () => {
      await searchNamespace();
      findSelectButton().vm.$emit('click');

      expect(wrapper.emitted('change')).toEqual([['test']]);
    });

    it('closes the listbox after the custom value for the namespace was selected', async () => {
      await searchNamespace();
      findSelectButton().vm.$emit('click');

      expect(closeMock).toHaveBeenCalled();
    });
  });

  describe('when environment has an associated namespace', () => {
    beforeEach(() => {
      wrapper = createWrapper({
        propsData: { namespace: 'existing-namespace' },
      });
    });

    it('updates namespace selector with the name of the associated namespace', () => {
      expect(findNamespaceSelector().props('toggleText')).toBe('existing-namespace');
    });
  });

  describe('on error', () => {
    const error = new Error('Error from the cluster_client API');

    beforeEach(async () => {
      wrapper = createWrapper({
        queryResult: jest.fn().mockRejectedValueOnce(error),
      });
      await waitForPromises();
    });

    it('renders an alert with the error text', () => {
      expect(findAlert().text()).toContain(error.message);
    });

    it('renders an empty namespace selector', () => {
      expect(findNamespaceSelector().props('items')).toMatchObject([]);
    });

    it('renders custom select button when the user performs search', async () => {
      await searchNamespace();

      expect(findSelectButton().exists()).toBe(true);
    });

    it('emits custom filled namespace name to the `change` event', async () => {
      await searchNamespace();
      findSelectButton().vm.$emit('click');

      expect(wrapper.emitted('change')).toEqual([['test']]);
    });
  });
});
