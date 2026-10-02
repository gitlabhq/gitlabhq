import { GlBadge, GlButton, GlFormCheckbox, GlIcon, GlLoadingIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective } from 'helpers/vue_mock_directive';
import {
  SCOPE_PICKER_ITEM_TYPE_GROUP,
  SCOPE_PICKER_ITEM_TYPE_PROJECT,
  SCOPE_PICKER_ITEM_TYPE_LOAD_MORE,
} from '~/explore/analytics_dashboards/components/constants';
import ScopePickerItem from '~/explore/analytics_dashboards/components/scope_picker_item.vue';

describe('ScopePickerItem', () => {
  let wrapper;

  const defaultProps = {
    value: 'gitlab-org',
    text: 'GitLab.org',
    itemType: SCOPE_PICKER_ITEM_TYPE_GROUP,
  };

  const createWrapper = (props = {}) => {
    wrapper = shallowMountExtended(ScopePickerItem, {
      propsData: { ...defaultProps, ...props },
      directives: { GlTooltip: createMockDirective('gl-tooltip') },
    });
  };

  const findItem = () => wrapper.findByTestId(`scope-picker-item-${defaultProps.value}`);
  const findCheckbox = () => wrapper.findComponent(GlFormCheckbox);
  const findName = () => wrapper.findByTestId('scope-picker-item-name');
  const findIcon = () => wrapper.findComponent(GlIcon);
  const findExpandButton = () => wrapper.findComponent(GlButton);
  const findParentName = () => wrapper.findByTestId('scope-picker-item-parent');
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findLoadMoreButton = () => wrapper.findComponentByTestId('scope-picker-load-more-button');
  const findRestrictedBadge = () => wrapper.findComponent(GlBadge);
  const findScreenReaderText = () => wrapper.find('.gl-sr-only');

  describe('default', () => {
    beforeEach(() => createWrapper());

    it('renders an item identified by the namespace path', () => {
      expect(findItem().exists()).toBe(true);
    });

    it('renders the namespace name', () => {
      expect(findName().text()).toBe(defaultProps.text);
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

    it('does not mark the item as inaccessible', () => {
      expect(findRestrictedBadge().exists()).toBe(false);
      expect(findScreenReaderText().exists()).toBe(false);
    });
  });

  describe.each`
    itemType                          | icon
    ${SCOPE_PICKER_ITEM_TYPE_GROUP}   | ${'folder-o'}
    ${SCOPE_PICKER_ITEM_TYPE_PROJECT} | ${'doc-text'}
  `('when itemType=$itemType', ({ itemType, icon }) => {
    beforeEach(() => createWrapper({ itemType }));

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

  describe.each`
    itemType                          | message
    ${SCOPE_PICKER_ITEM_TYPE_GROUP}   | ${"This group has restricted access, so you can't select it. You can select available projects and subgroups listed below it instead."}
    ${SCOPE_PICKER_ITEM_TYPE_PROJECT} | ${"This project has restricted access, so you can't select it."}
  `('when the user lacks access to an item with itemType=$itemType', ({ itemType, message }) => {
    beforeEach(() => createWrapper({ itemType, disabled: true, restricted: true }));

    it('renders a restricted badge outside the checkbox', () => {
      expect(findRestrictedBadge().exists()).toBe(true);
      expect(findRestrictedBadge().text()).toBe('Restricted');
      expect(findCheckbox().findComponent(GlBadge).exists()).toBe(false);
    });

    it('explains the restriction in a tooltip', () => {
      expect(findRestrictedBadge().attributes('title')).toBe(message);
    });

    it('lets the badge respond to hover on a disabled row', () => {
      expect(findRestrictedBadge().classes()).toContain('gl-pointer-events-auto');
    });

    it('gives the same explanation to assistive tech, outside the hidden checkbox', () => {
      expect(findScreenReaderText().text()).toBe(message);
      expect(findCheckbox().find('.gl-sr-only').exists()).toBe(false);
    });
  });

  describe('when the user lacks access to a namespace that sits below the group it is listed under', () => {
    beforeEach(() =>
      createWrapper({
        itemType: SCOPE_PICKER_ITEM_TYPE_PROJECT,
        parentName: 'Tools',
        disabled: true,
        restricted: true,
      }),
    );

    it('shows the restricted badge in place of the parent name', () => {
      expect(findRestrictedBadge().exists()).toBe(true);
      expect(findParentName().exists()).toBe(false);
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
    beforeEach(() =>
      createWrapper({ itemType: SCOPE_PICKER_ITEM_TYPE_PROJECT, parentName: 'Tools' }),
    );

    it('names the group it belongs to', () => {
      expect(findParentName().text()).toBe('in Tools');
    });

    it('leaves the name unescaped, Vue escaping the interpolation itself', () => {
      createWrapper({ itemType: SCOPE_PICKER_ITEM_TYPE_PROJECT, parentName: 'Sales & Marketing' });

      expect(findParentName().text()).toBe('in Sales & Marketing');
    });

    it('gives the full path in a tooltip, so the hierarchy is exact', () => {
      expect(findParentName().attributes('title')).toBe(defaultProps.value);
    });
  });

  describe('when rendering a Load More button', () => {
    const loadMoreProps = { itemType: SCOPE_PICKER_ITEM_TYPE_LOAD_MORE, text: 'Load more' };

    beforeEach(() => createWrapper(loadMoreProps));

    it('renders a button in place of a namespace', () => {
      expect(findLoadMoreButton().text()).toBe(loadMoreProps.text);
      expect(findCheckbox().exists()).toBe(false);
      expect(findIcon().exists()).toBe(false);
    });

    it('emits load-more when clicked, without selecting the row', () => {
      const event = { stopPropagation: jest.fn() };

      findLoadMoreButton().vm.$emit('click', event);

      expect(wrapper.emitted('load-more')).toHaveLength(1);
      expect(event.stopPropagation).toHaveBeenCalled();
    });

    // The listbox option the row sits in is disabled, which would otherwise swallow the click.
    it('keeps the button clickable', () => {
      expect(findLoadMoreButton().classes()).toContain('gl-pointer-events-auto');
    });

    it('renders an idle button until a page is asked for', () => {
      expect(findLoadMoreButton().props('loading')).toBe(false);
    });

    describe('while its page is in flight', () => {
      beforeEach(() => createWrapper({ ...loadMoreProps, loading: true }));

      it('sets the button to loading', () => {
        expect(findLoadMoreButton().props('loading')).toBe(true);
      });
    });

    describe('when it extends a group', () => {
      beforeEach(() => createWrapper({ ...loadMoreProps, nested: true }));

      it('indents to line up with the rows it extends', () => {
        expect(findItem().classes()).toContain('gl-pl-5');
      });
    });
  });

  describe('when no parent name is given', () => {
    beforeEach(() => createWrapper());

    it('renders no parent name', () => {
      expect(findParentName().exists()).toBe(false);
    });
  });
});
