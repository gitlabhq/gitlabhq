import { shallowMount } from '@vue/test-utils';

import IssuableBulkEditSidebar from '~/issuable_list/components/issuable_bulk_edit_sidebar.vue';

const createComponent = ({ expanded = true } = {}) =>
  shallowMount(IssuableBulkEditSidebar, {
    propsData: {
      expanded,
    },
    slots: {
      'bulk-edit-actions': `
        <button class="js-edit-issuables">Edit issuables</button>
      `,
      'sidebar-items': `
        <button class="js-sidebar-dropdown">Labels</button>
      `,
    },
  });

describe('IssuableBulkEditSidebar', () => {
  let wrapper;

  beforeEach(() => {
    setFixtures('<div class="layout-page right-sidebar-collapsed"></div>');
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('watch', () => {
    describe('expanded', () => {
      it.each`
        expanded | layoutPageClass
        ${true}  | ${'right-sidebar-expanded'}
        ${false} | ${'right-sidebar-collapsed'}
      `(
        'sets class "$layoutPageClass" on element `.layout-page` when expanded prop is $expanded',
        async ({ expanded, layoutPageClass }) => {
          const wrappeCustom = createComponent({
            expanded: !expanded,
          });

          // We need to manually flip the value of `expanded` for
          // watcher to trigger.
          wrappeCustom.setProps({
            expanded,
          });

          await wrappeCustom.vm.$nextTick();

          expect(document.querySelector('.layout-page').classList.contains(layoutPageClass)).toBe(
            true,
          );

          wrappeCustom.destroy();
        },
      );
    });
  });

  describe('template', () => {
    it.each`
      expanded | layoutPageClass
      ${true}  | ${'right-sidebar-expanded'}
      ${false} | ${'right-sidebar-collapsed'}
    `(
      'renders component container with class "$layoutPageClass" when expanded prop is $expanded',
      async ({ expanded, layoutPageClass }) => {
        const wrappeCustom = createComponent({
          expanded: !expanded,
        });

        // We need to manually flip the value of `expanded` for
        // watcher to trigger.
        wrappeCustom.setProps({
          expanded,
        });

        await wrappeCustom.vm.$nextTick();

        expect(wrappeCustom.classes()).toContain(layoutPageClass);

        wrappeCustom.destroy();
      },
    );

    it('renders contents for slot `bulk-edit-actions`', () => {
      expect(wrapper.find('button.js-edit-issuables').exists()).toBe(true);
    });

    it('renders contents for slot `sidebar-items`', () => {
      expect(wrapper.find('button.js-sidebar-dropdown').exists()).toBe(true);
    });
  });
});
