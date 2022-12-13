import { GlCollapsibleListbox, GlButton } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import AvailableAgentsDropdown from '~/clusters_list/components/available_agents_dropdown.vue';
import { I18N_AVAILABLE_AGENTS_DROPDOWN } from '~/clusters_list/constants';

describe('AvailableAgentsDropdown', () => {
  let wrapper;

  const configuredAgent = 'configured-agent';
  const searchAgentName = 'search-agent';
  const newAgentName = 'new-agent';

  const i18n = I18N_AVAILABLE_AGENTS_DROPDOWN;
  const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const findCreateButton = () => wrapper.findComponent(GlButton);

  const createWrapper = ({ propsData }) => {
    wrapper = shallowMountExtended(AvailableAgentsDropdown, {
      propsData,
      stubs: { GlCollapsibleListbox },
    });
    wrapper.vm.$refs.dropdown.closeAndFocus = jest.fn();
  };

  describe('there are agents available', () => {
    const propsData = {
      availableAgents: [configuredAgent, searchAgentName, 'test-agent'],
      isRegistering: false,
    };

    beforeEach(() => {
      createWrapper({ propsData });
    });

    it('prompts to select an agent', () => {
      expect(findDropdown().props('toggleText')).toBe(i18n.selectAgent);
    });

    describe('search agent', () => {
      it('renders search button', () => {
        expect(findDropdown().props('searchable')).toBe(true);
      });

      it('renders all agents when search term is empty', () => {
        expect(findDropdown().props('items')).toHaveLength(3);
      });

      it('renders only the agent searched for when the search item exists', async () => {
        findDropdown().vm.$emit('search', searchAgentName);
        await nextTick();

        expect(findDropdown().props('items')).toMatchObject([
          { text: searchAgentName, value: searchAgentName },
        ]);
      });

      describe('create button', () => {
        it.each`
          condition            | search             | createButtonRendered
          ${'is rendered'}     | ${newAgentName}    | ${true}
          ${'is not rendered'} | ${''}              | ${false}
          ${'is not rendered'} | ${searchAgentName} | ${false}
        `('$condition when search is "$search"', async ({ search, createButtonRendered }) => {
          findDropdown().vm.$emit('search', search);
          await nextTick();

          expect(findCreateButton().exists()).toBe(createButtonRendered);
        });
      });
    });

    describe('select existing agent configuration', () => {
      beforeEach(() => {
        findDropdown().vm.$emit('select', configuredAgent);
      });

      it('emits `agentSelected` with the name of the clicked agent', () => {
        expect(wrapper.emitted('agentSelected')).toEqual([[configuredAgent]]);
      });

      it('marks the clicked item as selected', () => {
        expect(findDropdown().props('toggleText')).toBe(configuredAgent);
      });
    });

    describe('create new agent configuration', () => {
      beforeEach(async () => {
        findDropdown().vm.$emit('search', newAgentName);
        await nextTick();
        findCreateButton().vm.$emit('click');
      });

      it('emits agentSelected with the name of the clicked agent', () => {
        expect(wrapper.emitted('agentSelected')).toEqual([[newAgentName]]);
      });

      it('marks the clicked item as selected', () => {
        expect(findDropdown().props('toggleText')).toBe(newAgentName);
      });
    });

    describe('click enter to register new agent without configuration', () => {
      beforeEach(async () => {
        const dropdown = findDropdown();
        dropdown.vm.$emit('search', newAgentName);
        await nextTick();
        await dropdown.trigger('keydown.enter');
      });

      it('emits agentSelected with the name of the clicked agent', () => {
        expect(wrapper.emitted('agentSelected')).toEqual([[newAgentName]]);
      });

      it('marks the clicked item as selected', () => {
        expect(findDropdown().props('toggleText')).toBe(newAgentName);
      });
    });
  });

  describe('registration in progress', () => {
    const propsData = {
      availableAgents: [configuredAgent],
      isRegistering: true,
    };

    beforeEach(() => {
      createWrapper({ propsData });
    });

    it('updates the text in the dropdown', () => {
      expect(findDropdown().props('toggleText')).toBe(i18n.registeringAgent);
    });

    it('displays a loading icon', () => {
      expect(findDropdown().props('loading')).toBe(true);
    });
  });
});
