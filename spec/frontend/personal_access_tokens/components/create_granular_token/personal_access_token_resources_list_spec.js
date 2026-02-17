import {
  GlButton,
  GlIcon,
  GlCollapse,
  GlFormCheckboxGroup,
  GlFormCheckbox,
  GlPopover,
} from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PersonalAccessTokenResourcesList from '~/personal_access_tokens/components/create_granular_token/personal_access_token_resources_list.vue';
import { mockGroupPermissions, mockGroupResources } from '../../mock_data';

describe('PersonalAccessTokenResourcesList', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(PersonalAccessTokenResourcesList, {
      propsData: {
        permissions: mockGroupPermissions,
        ...props,
      },
    });
  };

  const findCheckboxGroup = () => wrapper.findComponent(GlFormCheckboxGroup);
  const findCategoryButtons = () => wrapper.findAllComponents(GlButton);
  const findCategoryButton = (index) => wrapper.findAllComponents(GlButton).at(index);
  const findCollapses = () => wrapper.findAllComponents(GlCollapse);
  const findCollapse = (index) => findCollapses().at(index);
  const findIcon = (index) => findCategoryButtons().at(index).findComponent(GlIcon);
  const findCheckboxes = () => wrapper.findAllComponents(GlFormCheckbox);
  const findCheckbox = (index) => findCheckboxes().at(index);
  const findPopovers = () => wrapper.findAllComponents(GlPopover);
  const findPopover = (index) => findPopovers().at(index);

  beforeEach(() => {
    createComponent();
  });

  describe('rendering', () => {
    it('renders checkbox group', () => {
      expect(findCheckboxGroup().exists()).toBe(true);
    });

    it('renders category buttons', () => {
      expect(findCategoryButtons()).toHaveLength(2);

      expect(findCategoryButton(0).text()).toBe('Groups and projects');
      expect(findCategoryButton(1).text()).toBe('Merge request');
    });

    it('renders collapse components for each category', () => {
      expect(findCollapses()).toHaveLength(2);

      expect(findCollapse(0).props('visible')).toBe(false);
      expect(findCollapse(1).props('visible')).toBe(false);
    });
  });

  describe('category toggle', () => {
    it('expands category when button is clicked', async () => {
      await findCategoryButton(0).vm.$emit('click');

      expect(findCollapse(0).props('visible')).toBe(true);

      await findCategoryButton(0).vm.$emit('click');
      expect(findCollapse(0).props('visible')).toBe(false);
    });

    it('shows correct chevron icon based on expansion state', async () => {
      expect(findIcon(0).props('name')).toBe('chevron-right');

      await findCategoryButton(0).vm.$emit('click');
      await nextTick();

      expect(findIcon(0).props('name')).toBe('chevron-down');
    });
  });

  describe('resource checkboxes', () => {
    beforeEach(async () => {
      await findCategoryButton(0).vm.$emit('click');
      await findCategoryButton(1).vm.$emit('click');
    });

    it('renders checkboxes for each resource', () => {
      expect(findCheckboxes()).toHaveLength(2);

      expect(findCheckbox(0).text()).toBe('Project');
      expect(findCheckbox(0).attributes('value')).toBe('project');

      expect(findCheckbox(1).text()).toBe('Repository');
      expect(findCheckbox(1).attributes('value')).toBe('repository');
    });
  });

  describe('resource description', () => {
    it('renders popover with description for each resource', () => {
      expect(findPopovers()).toHaveLength(2);

      expect(findPopover(0).text()).toBe('Project resource description');
      expect(findPopover(0).attributes('target')).toBe('project');

      expect(findPopover(1).text()).toBe('Repository resource description');
      expect(findPopover(1).attributes('target')).toBe('repository');
    });
  });

  describe('events', () => {
    it('emits `input` event when selection changes', async () => {
      await findCheckboxGroup().vm.$emit('input', mockGroupResources);

      expect(wrapper.emitted('input')).toEqual([[mockGroupResources]]);
    });
  });
});
