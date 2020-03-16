import { shallowMount } from '@vue/test-utils';
import { GlLoadingIcon } from '@gitlab/ui';
import dropdownTitleComponent from '~/vue_shared/components/sidebar/labels_select/dropdown_title.vue';

const createComponent = (canEdit = true) =>
  shallowMount(dropdownTitleComponent, {
    propsData: {
      canEdit,
    },
  });

describe('DropdownTitleComponent', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('template', () => {
    it('renders title text', () => {
      expect(wrapper.vm.$el.classList.contains('title', 'hide-collapsed')).toBe(true);
      expect(wrapper.vm.$el.innerText.trim()).toContain('Labels');
    });

    it('renders spinner icon element', () => {
      expect(wrapper.find(GlLoadingIcon)).not.toBeNull();
    });

    it('renders `Edit` button element', () => {
      const editBtnEl = wrapper.vm.$el.querySelector('button.edit-link.js-sidebar-dropdown-toggle');

      expect(editBtnEl).not.toBeNull();
      expect(editBtnEl.innerText.trim()).toBe('Edit');
    });
  });
});
