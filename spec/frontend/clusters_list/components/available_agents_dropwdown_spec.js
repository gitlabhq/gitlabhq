import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { createLocalVue, mount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import AvailableAgentsDropdown from '~/clusters_list/components/available_agents_dropdown.vue';
import { I18N_AVAILABLE_AGENTS_DROPDOWN } from '~/clusters_list/constants';
import agentConfigurationsQuery from '~/clusters_list/graphql/queries/agent_configurations.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import { agentConfigurationsResponse } from './mock_data';

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('AvailableAgentsDropdown', () => {
  let wrapper;

  const i18n = I18N_AVAILABLE_AGENTS_DROPDOWN;
  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findConfiguredAgentItem = () => findDropdownItems().at(0);

  const createWrapper = ({ propsData = {}, isLoading = false }) => {
    const provide = {
      projectPath: 'path/to/project',
    };

    wrapper = (() => {
      if (isLoading) {
        const mocks = {
          $apollo: {
            queries: {
              agents: {
                loading: true,
              },
            },
          },
        };

        return mount(AvailableAgentsDropdown, { mocks, provide, propsData });
      }

      const apolloProvider = createMockApollo([
        [agentConfigurationsQuery, jest.fn().mockResolvedValue(agentConfigurationsResponse)],
      ]);

      return mount(AvailableAgentsDropdown, {
        localVue,
        apolloProvider,
        provide,
        propsData,
      });
    })();
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('there are agents available', () => {
    const propsData = {
      isRegistering: false,
    };

    beforeEach(() => {
      createWrapper({ propsData });
    });

    it('prompts to select an agent', () => {
      expect(findDropdown().props('text')).toBe(i18n.selectAgent);
    });

    it('shows only agents that are not yet installed', () => {
      expect(findDropdownItems()).toHaveLength(1);
      expect(findConfiguredAgentItem().text()).toBe('configured-agent');
      expect(findConfiguredAgentItem().props('isChecked')).toBe(false);
    });

    describe('click events', () => {
      beforeEach(() => {
        findConfiguredAgentItem().vm.$emit('click');
      });

      it('emits agentSelected with the name of the clicked agent', () => {
        expect(wrapper.emitted('agentSelected')).toEqual([['configured-agent']]);
      });

      it('marks the clicked item as selected', () => {
        expect(findDropdown().props('text')).toBe('configured-agent');
        expect(findConfiguredAgentItem().props('isChecked')).toBe(true);
      });
    });
  });

  describe('registration in progress', () => {
    const propsData = {
      isRegistering: true,
    };

    beforeEach(() => {
      createWrapper({ propsData });
    });

    it('updates the text in the dropdown', () => {
      expect(findDropdown().props('text')).toBe(i18n.registeringAgent);
    });

    it('displays a loading icon', () => {
      expect(findDropdown().props('loading')).toBe(true);
    });
  });

  describe('agents query is loading', () => {
    const propsData = {
      isRegistering: false,
    };

    beforeEach(() => {
      createWrapper({ propsData, isLoading: true });
    });

    it('updates the text in the dropdown', () => {
      expect(findDropdown().text()).toBe(i18n.selectAgent);
    });

    it('displays a loading icon', () => {
      expect(findDropdown().props('loading')).toBe(true);
    });
  });
});
