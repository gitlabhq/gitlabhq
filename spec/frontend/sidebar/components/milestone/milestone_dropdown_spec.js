import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { TYPE_ISSUE, WORKSPACE_PROJECT } from '~/issues/constants';
import MilestoneDropdown from '~/sidebar/components/milestone/milestone_dropdown.vue';
import SidebarDropdown from '~/sidebar/components/sidebar_dropdown.vue';

describe('MilestoneDropdown component', () => {
  let wrapper;

  const propsData = {
    attrWorkspacePath: 'full/path',
    issuableType: TYPE_ISSUE,
    workspaceType: WORKSPACE_PROJECT,
  };

  const findHiddenInput = () => wrapper.find('input');
  const findSidebarDropdown = () => wrapper.findComponent(SidebarDropdown);

  const createComponent = (props = {}) => {
    wrapper = shallowMount(MilestoneDropdown, { propsData: { ...propsData, ...props } });
  };

  it('renders SidebarDropdown', () => {
    createComponent();

    expect(findSidebarDropdown().props()).toMatchObject({
      attrWorkspacePath: propsData.attrWorkspacePath,
      issuableAttribute: MilestoneDropdown.issuableAttribute,
      issuableType: propsData.issuableType,
      workspaceType: propsData.workspaceType,
    });
  });

  it('renders hidden input', () => {
    createComponent();

    expect(findHiddenInput().attributes()).toEqual({
      type: 'hidden',
      name: 'update[milestone_id]',
      value: undefined,
    });
  });

  describe('when milestone ID and title is provided', () => {
    it('is used in the dropdown and hidden input', () => {
      const milestone = {
        id: 'gid://gitlab/Milestone/52',
        title: 'Milestone 52',
      };
      createComponent({ milestoneId: milestone.id, milestoneTitle: milestone.title });

      expect(findSidebarDropdown().props('currentAttribute')).toEqual(milestone);
      expect(findHiddenInput().attributes('value')).toBe(
        getIdFromGraphQLId(milestone.id).toString(),
      );
    });
  });

  describe('when SidebarDropdown emits `change` event', () => {
    beforeEach(() => {
      createComponent();
    });

    describe('when valid milestone is emitted', () => {
      it('updates the hidden input value', async () => {
        const milestone = {
          id: 'gid://gitlab/Milestone/52',
          title: 'Milestone 52',
        };

        findSidebarDropdown().vm.$emit('change', milestone);
        await nextTick();

        expect(findHiddenInput().attributes('value')).toBe(
          getIdFromGraphQLId(milestone.id).toString(),
        );
      });
    });

    describe('when null milestone is emitted', () => {
      it('updates the hidden input value to `0`', async () => {
        const milestone = { id: null };

        findSidebarDropdown().vm.$emit('change', milestone);
        await nextTick();

        expect(findHiddenInput().attributes('value')).toBe('0');
      });
    });
  });
});
