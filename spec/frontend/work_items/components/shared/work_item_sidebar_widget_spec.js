import { GlLoadingIcon } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { Mousetrap } from '~/lib/mousetrap';
import WorkItemSidebarWidget from '~/work_items/components/shared/work_item_sidebar_widget.vue';

describe('WorkItemSidebarWidget component', () => {
  let wrapper;

  const findApplyButton = () => wrapper.findByTestId('apply-button');
  const findEditButton = () => wrapper.findByTestId('edit-button');

  const createComponent = ({ canUpdate = false, isUpdating = false, tooltipText } = {}) => {
    wrapper = shallowMountExtended(WorkItemSidebarWidget, {
      propsData: {
        canUpdate,
        isUpdating,
        tooltipText,
      },
      slots: {
        title: 'Title',
        content: 'Content',
        'editing-content': 'Editing',
      },
    });
  };

  it('renders heading with title', () => {
    createComponent();

    expect(wrapper.find('h3').text()).toBe('Title');
  });

  describe('when cannot edit', () => {
    beforeEach(() => {
      createComponent({ canUpdate: false });
    });

    it('does not render Edit button', () => {
      expect(findEditButton().exists()).toBe(false);
    });

    it('renders content', () => {
      expect(wrapper.text()).toContain('Content');
    });

    it('does not render editing content', () => {
      expect(wrapper.text()).not.toContain('Editing');
    });
  });

  describe('when can edit', () => {
    describe('when not editing', () => {
      beforeEach(() => {
        createComponent({ canUpdate: true, tooltipText: 'I am a tooltip' });
      });

      it('renders Edit button', () => {
        expect(findEditButton().text()).toBe('Edit');
      });

      it('does not render Apply button', () => {
        expect(findApplyButton().exists()).toBe(false);
      });

      it('renders content', () => {
        expect(wrapper.text()).toContain('Content');
      });

      it('does not render editing content', () => {
        expect(wrapper.text()).not.toContain('Editing');
      });

      it('emits "startEditing" event when edit button is clicked', () => {
        findEditButton().vm.$emit('click');

        expect(wrapper.emitted('startEditing')).toEqual([[]]);
      });

      it('renders tooltip', () => {
        expect(findEditButton().attributes('title')).toBe('I am a tooltip');
      });
    });

    describe('when editing', () => {
      beforeEach(() => {
        createComponent({ canUpdate: true });
        findEditButton().vm.$emit('click');
      });

      it('does not render Edit button', () => {
        expect(findEditButton().exists()).toBe(false);
      });

      it('renders Apply button', () => {
        expect(findApplyButton().text()).toBe('Apply');
      });

      it('does not render content', () => {
        expect(wrapper.text()).not.toContain('Content');
      });

      it('renders editing content', () => {
        expect(wrapper.text()).toContain('Editing');
      });

      it('emits "stopEditing" event when apply button is clicked', () => {
        findApplyButton().vm.$emit('click');

        expect(wrapper.emitted('stopEditing')).toEqual([[]]);
      });

      it('stops editing when the Esc key is pressed', async () => {
        Mousetrap.trigger('esc');
        await nextTick();

        expect(wrapper.text()).toContain('Content');
        expect(findEditButton().exists()).toBe(true);
        expect(wrapper.text()).not.toContain('Editing');
        expect(findApplyButton().exists()).toBe(false);
        expect(wrapper.emitted('stopEditing')).toEqual([[]]);
      });
    });

    describe('when updating', () => {
      beforeEach(() => {
        createComponent({ canUpdate: true, isUpdating: true });
      });

      it('renders Edit button as disabled', () => {
        expect(findEditButton().props('disabled')).toBe(true);
      });

      it('shows loading icon', () => {
        expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
      });
    });
  });

  describe('"isEditing" watcher', () => {
    it('updates component as it changes', async () => {
      createComponent({ canUpdate: true });

      expect(findEditButton().exists()).toBe(true);
      expect(wrapper.text()).toContain('Content');

      await wrapper.setProps({ isEditing: true });

      expect(findApplyButton().exists()).toBe(true);
      expect(wrapper.text()).toContain('Editing');

      await wrapper.setProps({ isEditing: false });

      expect(findEditButton().exists()).toBe(true);
      expect(wrapper.text()).toContain('Content');
    });
  });

  describe('Mousetrap binding', () => {
    it('binds and unbinds on mount and destroy', () => {
      jest.spyOn(Mousetrap, 'bind');
      jest.spyOn(Mousetrap, 'unbind');

      createComponent();

      expect(Mousetrap.bind).toHaveBeenCalledWith(['esc'], expect.any(Function));

      wrapper.destroy();

      expect(Mousetrap.unbind).toHaveBeenCalledWith(['esc']);
    });
  });
});
