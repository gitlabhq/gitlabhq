import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import AvailableAgentsDropdown from '~/clusters_list/components/available_agents_dropdown.vue';
import { I18N_AVAILABLE_AGENTS_DROPDOWN } from '~/clusters_list/constants';

describe('AvailableAgentsDropdown', () => {
  let wrapper;

  const i18n = I18N_AVAILABLE_AGENTS_DROPDOWN;
  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findConfiguredAgentItem = () => findDropdownItems().at(0);

  const createWrapper = ({ propsData }) => {
    wrapper = shallowMount(AvailableAgentsDropdown, {
      propsData,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('there are agents available', () => {
    const propsData = {
      availableAgents: ['configured-agent'],
      isRegistering: false,
    };

    beforeEach(() => {
      createWrapper({ propsData });
    });

    it('prompts to select an agent', () => {
      expect(findDropdown().props('text')).toBe(i18n.selectAgent);
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
      availableAgents: ['configured-agent'],
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
});
