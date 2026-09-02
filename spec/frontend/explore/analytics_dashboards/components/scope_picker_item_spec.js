import { GlButton, GlFormCheckbox, GlIcon, GlLoadingIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective } from 'helpers/vue_mock_directive';
import { TYPENAME_GROUP, TYPENAME_PROJECT } from '~/graphql_shared/constants';
import ScopePickerItem from '~/explore/analytics_dashboards/components/scope_picker_item.vue';

describe('ScopePickerItem', () => {
  let wrapper;

  const defaultProps = {
    value: 'gitlab-org',
    text: 'GitLab.org',
    namespaceType: TYPENAME_GROUP,
  };

  const createWrapper = (props = {}) => {
    wrapper = shallowMountExtended(ScopePickerItem, {
      propsData: { ...defaultProps, ...props },
      directives: { GlTooltip: createMockDirective('gl-tooltip') },
    });
  };

  const findItem = () => wrapper.findByTestId(`scope-picker-item-${defaultProps.value}`);
  const findCheckbox = () => wrapper.findComponent(GlFormCheckbox);
  const findIcon = () => wrapper.findComponent(GlIcon);
  const findExpandButton = () => wrapper.findComponent(GlButton);
  const findParentName = () => wrapper.findByTestId('scope-picker-item-parent');
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  describe('default', () => {
    beforeEach(() => createWrapper());

    it('renders an item identified by the namespace path', () => {
      expect(findItem().exists()).toBe(true);
    });

    it('renders the namespace name', () => {
      expect(findCheckbox().text()).toBe(defaultProps.text);
    });

    it('renders an unchecked, enabled checkbox', () => {
      expect(findCheckbox().attributes('checked')).toBeUndefined();
      expect(findCheckbox().attributes('disabled')).toBeUndefined();
    });

    it('renders the checkbox as a presentational mirror of the listbox option', () => {
      expect(findCheckbox().attributes()).toMatchObject({
        'aria-hidden': 'true',
        tabindex: '-1',
      });
      expect(findCheckbox().classes()).toContain('gl-pointer-events-none');
    });

    it('does not render the expand button', () => {
      expect(findExpandButton().exists()).toBe(false);
    });

    it('does not indent the item', () => {
      expect(findItem().classes()).not.toContain('gl-pl-5');
    });
  });

  describe.each`
    namespaceType       | icon
    ${TYPENAME_GROUP}   | ${'folder-o'}
    ${TYPENAME_PROJECT} | ${'doc-text'}
  `('when the namespace is a $namespaceType', ({ namespaceType, icon }) => {
    beforeEach(() => createWrapper({ namespaceType }));

    it(`renders the ${icon} icon`, () => {
      expect(findIcon().props('name')).toBe(icon);
    });
  });

  describe('when selected', () => {
    beforeEach(() => createWrapper({ selected: true }));

    it('checks the checkbox', () => {
      expect(findCheckbox().attributes('checked')).toBe('true');
    });
  });

  describe('when indeterminate', () => {
    beforeEach(() => createWrapper({ indeterminate: true }));

    it('sets the checkbox to indeterminate', () => {
      expect(findCheckbox().attributes('indeterminate')).toBe('true');
      expect(findCheckbox().attributes('checked')).toBeUndefined();
    });
  });

  describe('when disabled', () => {
    beforeEach(() => createWrapper({ disabled: true }));

    it('disables the checkbox', () => {
      expect(findCheckbox().attributes('disabled')).toBeDefined();
    });
  });

  describe('when nested', () => {
    beforeEach(() => createWrapper({ nested: true }));

    it('indents the item', () => {
      expect(findItem().classes()).toContain('gl-pl-5');
    });
  });

  describe('when expandable', () => {
    beforeEach(() => createWrapper({ expandable: true }));

    it('renders a collapsed expand button', () => {
      expect(findExpandButton().props('icon')).toBe('chevron-right');
      expect(findExpandButton().attributes('aria-expanded')).toBe('false');
      expect(findExpandButton().attributes('aria-label')).toBe('Expand GitLab.org');
    });

    it('emits toggle-expanded when clicked, without selecting the item', () => {
      const event = { stopPropagation: jest.fn() };

      findExpandButton().vm.$emit('click', event);

      expect(wrapper.emitted('toggle-expanded')).toHaveLength(1);
      expect(event.stopPropagation).toHaveBeenCalled();
    });

    it('renders no loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    describe('and expanded', () => {
      beforeEach(() => createWrapper({ expandable: true, expanded: true }));

      it('renders an expanded expand button', () => {
        expect(findExpandButton().props('icon')).toBe('chevron-down');
        expect(findExpandButton().attributes('aria-expanded')).toBe('true');
        expect(findExpandButton().attributes('aria-label')).toBe('Collapse GitLab.org');
      });
    });

    describe('and expanding', () => {
      beforeEach(() => createWrapper({ expandable: true, expanding: true }));

      it('renders a loading icon', () => {
        expect(findLoadingIcon().exists()).toBe(true);
      });

      it('keeps the row collapsible, so a slow fetch cannot strand it open', () => {
        expect(findExpandButton().props('loading')).toBe(false);

        findExpandButton().vm.$emit('click', { stopPropagation: jest.fn() });

        expect(wrapper.emitted('toggle-expanded')).toHaveLength(1);
      });
    });
  });

  describe('when disabled by a selected ancestor', () => {
    beforeEach(() => createWrapper({ expandable: true, disabled: true }));

    it('keeps the chevron clickable, so the row can still be browsed', () => {
      expect(findExpandButton().exists()).toBe(true);
      expect(wrapper.find('.gl-pointer-events-auto').exists()).toBe(true);
    });
  });

  describe('when the namespace sits below the group it is listed under', () => {
    beforeEach(() => createWrapper({ namespaceType: TYPENAME_PROJECT, parentName: 'Tools' }));

    it('names the group it belongs to', () => {
      expect(findParentName().text()).toBe('(Tools)');
    });

    it('gives the full path in a tooltip, so the hierarchy is exact', () => {
      expect(findParentName().attributes('title')).toBe(defaultProps.value);
    });
  });

  describe('when no parent name is given', () => {
    beforeEach(() => createWrapper());

    it('renders no parent name', () => {
      expect(findParentName().exists()).toBe(false);
    });
  });
});
