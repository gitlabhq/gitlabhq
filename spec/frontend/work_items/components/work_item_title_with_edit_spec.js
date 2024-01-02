import { GlFormGroup, GlFormInput } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemTitleWithEdit from '~/work_items/components/work_item_title_with_edit.vue';

describe('Work Item title with edit', () => {
  let wrapper;
  const mockTitle = 'Work Item title';

  const createComponent = ({ isEditing = false } = {}) => {
    wrapper = shallowMountExtended(WorkItemTitleWithEdit, {
      propsData: {
        title: mockTitle,
        isEditing,
      },
    });
  };

  const findTitle = () => wrapper.findByTestId('work-item-title');
  const findEditableTitleForm = () => wrapper.findComponent(GlFormGroup);
  const findEditableTitleInput = () => wrapper.findComponent(GlFormInput);

  describe('Default mode', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders title', () => {
      expect(findTitle().exists()).toBe(true);
      expect(findTitle().text()).toBe(mockTitle);
    });

    it('does not render edit mode', () => {
      expect(findEditableTitleForm().exists()).toBe(false);
    });
  });

  describe('Edit mode', () => {
    beforeEach(() => {
      createComponent({ isEditing: true });
    });

    it('does not render read only title', () => {
      expect(findTitle().exists()).toBe(false);
    });

    it('renders the editable title with label', () => {
      expect(findEditableTitleForm().exists()).toBe(true);
      expect(findEditableTitleForm().attributes('label')).toBe(
        WorkItemTitleWithEdit.i18n.titleLabel,
      );
    });

    it('emits `updateDraft` event on change of the input', () => {
      findEditableTitleInput().vm.$emit('input', 'updated title');

      expect(wrapper.emitted('updateDraft')).toEqual([['updated title']]);
    });
  });
});
