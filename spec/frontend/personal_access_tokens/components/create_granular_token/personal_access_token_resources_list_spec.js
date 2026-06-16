import {
  GlButton,
  GlCollapse,
  GlFormCheckboxGroup,
  GlFormCheckbox,
  GlPopover,
  GlAnimatedChevronRightDownIcon,
} from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PersonalAccessTokenResourcesList from '~/personal_access_tokens/components/create_granular_token/personal_access_token_resources_list.vue';
import { stubComponent } from 'helpers/stub_component';
import { mockGroupPermissions, mockGroupResources } from '../../mock_data';

describe('PersonalAccessTokenResourcesList', () => {
  let wrapper;

  const createComponent = ({ isFiltering = false, value = [] } = {}) => {
    wrapper = shallowMountExtended(PersonalAccessTokenResourcesList, {
      propsData: {
        scope: 'namespace',
        permissions: mockGroupPermissions,
        isFiltering,
        value,
      },
      stubs: {
        GlAnimatedChevronRightDownIcon: stubComponent(GlAnimatedChevronRightDownIcon, {
          props: ['isOn'],
        }),
      },
    });
  };

  const findCheckboxGroups = () => wrapper.findAllComponents(GlFormCheckboxGroup);
  const findCategoryButtons = () => wrapper.findAllComponents(GlButton);
  const findCategoryNames = () => wrapper.findAllByTestId('category-name');
  const findCollapses = () => wrapper.findAllComponents(GlCollapse);
  const findChevron = () => wrapper.findComponent(GlAnimatedChevronRightDownIcon);
  const findCategoryCheckboxes = () => wrapper.findAllByTestId('category-select-all');
  const findResourceCheckboxes = () =>
    wrapper
      .findAllComponents(GlFormCheckbox)
      .filter((c) => c.attributes('data-testid') !== 'category-select-all');
  const findPopovers = () => wrapper.findAllComponents(GlPopover);

  const clickCategoryButton = (index) => {
    findCategoryButtons().at(index).vm.$emit('click');
    return nextTick();
  };

  beforeEach(() => createComponent());

  describe('props validation', () => {
    it('validates `scope` prop correctly', () => {
      const { validator } = PersonalAccessTokenResourcesList.props.scope;

      expect(validator('namespace')).toBe(true);
      expect(validator('user')).toBe(true);
      expect(validator('invalid')).toBe(false);
      expect(validator('')).toBe(false);
    });
  });

  describe('rendering', () => {
    it('renders a toggle button for each category', () => {
      expect(findCategoryButtons()).toHaveLength(2);
    });

    it('renders the category names', () => {
      expect(findCategoryNames().at(0).text()).toBe('Groups and projects');
      expect(findCategoryNames().at(1).text()).toBe('Merge request');
    });

    it('renders collapse components for each category', () => {
      expect(findCollapses()).toHaveLength(2);

      expect(findCollapses().at(0).props('visible')).toBe(false);
      expect(findCollapses().at(1).props('visible')).toBe(false);
    });
  });

  describe('category toggle', () => {
    describe('when category is toggled open', () => {
      beforeEach(() => clickCategoryButton(0));

      it('shows permissions list', () => {
        expect(findCollapses().at(0).props('visible')).toBe(true);
      });

      it('shows chevron as open', () => {
        expect(findChevron().props('isOn')).toBe(true);
      });
    });

    describe('when category is toggled closed', () => {
      beforeEach(() => {
        clickCategoryButton(0); // Toggle open.
        clickCategoryButton(0); // Toggle closed.
      });

      it('hides permissions list', () => {
        expect(findCollapses().at(0).props('visible')).toBe(false);
      });

      it('shows chevron as closed', () => {
        expect(findChevron().props('isOn')).toBe(false);
      });
    });

    describe('when filtering permissions', () => {
      beforeEach(() => {
        wrapper.setProps({ isFiltering: true });
      });

      it('disables category button', () => {
        expect(findCategoryButtons().at(0).props('disabled')).toBe(true);
      });

      it('shows permissions list', () => {
        expect(findCollapses().at(0).props('visible')).toBe(true);
      });

      it('shows chevron as opened', () => {
        expect(findChevron().props('isOn')).toBe(true);
      });
    });
  });

  describe('resource checkboxes', () => {
    beforeEach(() => {
      clickCategoryButton(0);
      return clickCategoryButton(1);
    });

    it('renders checkboxes for each resource', () => {
      expect(findResourceCheckboxes()).toHaveLength(3);

      expect(findResourceCheckboxes().at(0).text()).toBe('Project');
      expect(findResourceCheckboxes().at(0).attributes('value')).toBe('project');

      expect(findResourceCheckboxes().at(1).text()).toBe('Contributed project');
      expect(findResourceCheckboxes().at(1).attributes('value')).toBe('contributed_project');

      expect(findResourceCheckboxes().at(2).text()).toBe('Repository');
      expect(findResourceCheckboxes().at(2).attributes('value')).toBe('repository');
    });
  });

  describe('resource description', () => {
    it('renders popover with description for each resource', () => {
      expect(findPopovers()).toHaveLength(3);

      expect(findPopovers().at(0).text()).toBe('Project resource description');
      expect(findPopovers().at(0).attributes('target')).toBe('namespace-project');

      expect(findPopovers().at(1).text()).toBe('Contributed project resource description');
      expect(findPopovers().at(1).attributes('target')).toBe('namespace-contributed_project');

      expect(findPopovers().at(2).text()).toBe('Repository resource description');
      expect(findPopovers().at(2).attributes('target')).toBe('namespace-repository');
    });
  });

  describe('events', () => {
    it('emits `input` event when selection changes', async () => {
      await findCheckboxGroups().at(0).vm.$emit('input', mockGroupResources);

      expect(wrapper.emitted('input')).toEqual([[mockGroupResources]]);
    });
  });

  describe('category select-all checkbox', () => {
    // `Groups and projects` (category = 0) has `project` + `contributed_project`.
    // `Merge request` (category = 1) has `repository`.
    it('renders a select-all checkbox for each category', () => {
      expect(findCategoryCheckboxes()).toHaveLength(2);
    });

    it('is unchecked and not indeterminate when no resource is selected', () => {
      expect(findCategoryCheckboxes().at(0).props('checked')).toBe(false);
      expect(findCategoryCheckboxes().at(0).props('indeterminate')).toBe(false);
    });

    it('is checked when every resource in the category is selected', () => {
      createComponent({ value: ['project', 'contributed_project'] });

      expect(findCategoryCheckboxes().at(0).props('checked')).toBe(true);
      expect(findCategoryCheckboxes().at(0).props('indeterminate')).toBe(false);
    });

    it('is indeterminate when only some resources in the category are selected', () => {
      createComponent({ value: ['project'] });

      expect(findCategoryCheckboxes().at(0).props('checked')).toBe(false);
      expect(findCategoryCheckboxes().at(0).props('indeterminate')).toBe(true);
    });

    describe('when checked', () => {
      it('adds every resource in the category to the selection', () => {
        createComponent({ value: [] });

        findCategoryCheckboxes().at(0).vm.$emit('change', true);

        expect(wrapper.emitted('input')).toEqual([[['project', 'contributed_project']]]);
      });

      it('preserves selections from other categories', () => {
        createComponent({ value: ['repository'] });

        findCategoryCheckboxes().at(0).vm.$emit('change', true);

        expect(wrapper.emitted('input')).toEqual([
          [['repository', 'project', 'contributed_project']],
        ]);
      });
    });

    describe('when unchecked', () => {
      it("removes only that category's resources from the selection", () => {
        createComponent({ value: ['project', 'contributed_project', 'repository'] });

        findCategoryCheckboxes().at(0).vm.$emit('change', false);

        expect(wrapper.emitted('input')).toEqual([[['repository']]]);
      });
    });
  });
});
