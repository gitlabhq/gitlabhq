import { GlDropdown, GlDropdownItem, GlSearchBoxByType } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { ENTER_KEY } from '~/lib/utils/keys';
import AvailableAgentsDropdown from '~/clusters_list/components/available_agents_dropdown.vue';
import { I18N_AVAILABLE_AGENTS_DROPDOWN } from '~/clusters_list/constants';

describe('AvailableAgentsDropdown', () => {
  let wrapper;

  const i18n = I18N_AVAILABLE_AGENTS_DROPDOWN;
  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findFirstAgentItem = () => findDropdownItems().at(0);
  const findSearchInput = () => wrapper.findComponent(GlSearchBoxByType);
  const findCreateButton = () => wrapper.findByTestId('create-config-button');

  const createWrapper = ({ propsData }) => {
    wrapper = shallowMountExtended(AvailableAgentsDropdown, {
      propsData,
      stubs: { GlDropdown },
    });
    wrapper.vm.$refs.dropdown.hide = jest.fn();
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('there are agents available', () => {
    const propsData = {
      availableAgents: ['configured-agent', 'search-agent', 'test-agent'],
      isRegistering: false,
    };

    beforeEach(() => {
      createWrapper({ propsData });
    });

    it('prompts to select an agent', () => {
      expect(findDropdown().props('text')).toBe(i18n.selectAgent);
    });

    describe('search agent', () => {
      it('renders search button', () => {
        expect(findSearchInput().exists()).toBe(true);
      });

      it('renders all agents when search term is empty', () => {
        expect(findDropdownItems()).toHaveLength(3);
      });

      it('renders only the agent searched for when the search item exists', async () => {
        await findSearchInput().vm.$emit('input', 'search-agent');

        expect(findDropdownItems()).toHaveLength(1);
        expect(findFirstAgentItem().text()).toBe('search-agent');
      });

      it('renders create button when search started', async () => {
        await findSearchInput().vm.$emit('input', 'new-agent');

        expect(findCreateButton().exists()).toBe(true);
      });

      it("doesn't render create button when search item is found", async () => {
        await findSearchInput().vm.$emit('input', 'search-agent');

        expect(findCreateButton().exists()).toBe(false);
      });
    });

    describe('select existing agent configuration', () => {
      beforeEach(() => {
        findFirstAgentItem().vm.$emit('click');
      });

      it('emits agentSelected with the name of the clicked agent', () => {
        expect(wrapper.emitted('agentSelected')).toEqual([['configured-agent']]);
      });

      it('marks the clicked item as selected', () => {
        expect(findDropdown().props('text')).toBe('configured-agent');
        expect(findFirstAgentItem().props('isChecked')).toBe(true);
      });
    });

    describe('create new agent configuration', () => {
      beforeEach(async () => {
        await findSearchInput().vm.$emit('input', 'new-agent');
        findCreateButton().vm.$emit('click');
      });

      it('emits agentSelected with the name of the clicked agent', () => {
        expect(wrapper.emitted('agentSelected')).toEqual([['new-agent']]);
      });

      it('marks the clicked item as selected', () => {
        expect(findDropdown().props('text')).toBe('new-agent');
      });
    });

    describe('click enter to register new agent without configuration', () => {
      beforeEach(async () => {
        await findSearchInput().vm.$emit('input', 'new-agent');
        await findSearchInput().vm.$emit('keydown', new KeyboardEvent({ key: ENTER_KEY }));
      });

      it('emits agentSelected with the name of the clicked agent', () => {
        expect(wrapper.emitted('agentSelected')).toEqual([['new-agent']]);
      });

      it('marks the clicked item as selected', () => {
        expect(findDropdown().props('text')).toBe('new-agent');
      });

      it('closes the dropdown', () => {
        expect(wrapper.vm.$refs.dropdown.hide).toHaveBeenCalledTimes(1);
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
