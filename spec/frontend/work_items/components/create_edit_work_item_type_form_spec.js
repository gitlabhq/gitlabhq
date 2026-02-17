import { GlModal, GlFormRadio, GlFormRadioGroup } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';

import CreateEditWorkItemTypeForm from '~/work_items/components/create_edit_work_item_type_form.vue';
import {
  WI_TYPE_ICON_SELECTION_SET_SCREEN_READER_TEXT_MAP,
  WORK_ITEM_ICON_OPTIONS as ICON_OPTIONS,
} from '~/work_items/constants';

describe('CreateEditWorkItemTypeForm', () => {
  let wrapper;

  const createComponent = ({
    isVisible = true,
    isEditMode = false,
    workItemType = null,
    isLoading = false,
  } = {}) => {
    wrapper = shallowMountExtended(CreateEditWorkItemTypeForm, {
      propsData: {
        isVisible,
        isEditMode,
        workItemType,
        isLoading,
      },
      stubs: {
        GlModal: stubComponent(GlModal, {
          template:
            '<div><slot name="modal-title"></slot><slot></slot><slot name="modal-footer"></slot></div>',
        }),
      },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findNameInput = () => wrapper.findByTestId('work-item-type-name-input');
  const findSubmitButton = () => wrapper.findByTestId('work-item-type-submit-button');
  const findCancelButton = () => wrapper.findByTestId('work-item-type-cancel-button');
  const findIconLabels = () => wrapper.findAll('label[role="radio"]');
  const findIconRadioGroup = () => wrapper.findComponent(GlFormRadioGroup);

  describe('Default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the form with name input and icon selection with all icons', () => {
      expect(findNameInput().exists()).toBe(true);
      expect(findIconRadioGroup().exists()).toBe(true);
      expect(findIconLabels()).toHaveLength(ICON_OPTIONS.length);
    });

    it('renders submit and cancel buttons', () => {
      expect(findSubmitButton().exists()).toBe(true);
      expect(findCancelButton().exists()).toBe(true);
    });
  });

  describe('modal title', () => {
    it('shows "New type" title in create mode', () => {
      createComponent();

      expect(findModal().props('title')).toBe('New type');
    });

    it('shows "Edit type name and icon" title in edit mode', () => {
      createComponent({ isEditMode: true });

      expect(findModal().props('title')).toBe('Edit type name and icon');
    });
  });

  describe('submit button text', () => {
    it('shows "Save" button text in create mode', () => {
      createComponent();

      expect(findSubmitButton().text()).toBe('Save');
    });

    it('shows "Save" button text in edit mode', () => {
      createComponent({ isEditMode: true });

      expect(findSubmitButton().text()).toBe('Save');
    });
  });

  describe('form initialization', () => {
    it('initializes form with empty values in create mode', () => {
      createComponent();

      expect(findNameInput().attributes('value')).toBe('');
    });

    it('initializes form with work item type data in edit mode', () => {
      const workItemType = {
        name: 'Custom Type',
        iconName: 'work-item-task',
      };

      createComponent({ isEditMode: true, workItemType });

      expect(findNameInput().attributes('value')).toBe('Custom Type');
    });
  });

  it('enforces maxlength of 48 characters on name input', () => {
    createComponent();

    expect(findNameInput().attributes('maxlength')).toBe('48');
  });

  describe('icon selection', () => {
    it('renders all icon options with correct attributes', () => {
      createComponent();

      const labels = findIconLabels();
      expect(labels).toHaveLength(ICON_OPTIONS.length);

      labels.wrappers.forEach((label, index) => {
        const iconName = ICON_OPTIONS[index];
        const expectedLabel = WI_TYPE_ICON_SELECTION_SET_SCREEN_READER_TEXT_MAP[iconName];
        expect(label.attributes('aria-label')).toBe(expectedLabel);
        expect(label.attributes('role')).toBe('radio');
      });
    });

    it('updates icon when clicking on an icon option', async () => {
      createComponent();

      const secondIconLabel = findIconLabels().at(1);
      secondIconLabel.trigger('click');
      await nextTick();

      const selectedLabel = findIconLabels().wrappers.find(
        (label) => label.attributes('aria-checked') === 'true',
      );

      expect(selectedLabel.attributes('aria-label')).toContain('Stack');
    });

    it('sets correct tabindex for icon options', async () => {
      createComponent();

      const secondIconLabel = findIconLabels().at(1);
      await secondIconLabel.trigger('click');
      await nextTick();

      const labels = findIconLabels();
      labels.wrappers.forEach((label) => {
        const isSelected = label.attributes('aria-checked') === 'true';
        const expectedTabindex = isSelected ? '0' : '-1';
        expect(label.attributes('tabindex')).toBe(expectedTabindex);
      });
    });
  });

  describe('keyboard navigation', () => {
    it('has icon selection group', () => {
      createComponent();
      expect(findIconRadioGroup().exists()).toBe(true);
    });

    it('supports icon selection with click', async () => {
      createComponent();

      const firstIcon = findIconLabels().at(0);
      await firstIcon.trigger('click');
      await nextTick();

      expect(firstIcon.attributes('aria-checked')).toBe('true');
    });

    it('updates tabindex when icon selection changes', async () => {
      createComponent();

      const firstIcon = findIconLabels().at(0);
      const secondIcon = findIconLabels().at(1);

      await secondIcon.trigger('click');
      await nextTick();

      expect(firstIcon.attributes('tabindex')).toBe('-1');
      expect(secondIcon.attributes('tabindex')).toBe('0');
    });
  });

  describe('accessibility', () => {
    beforeEach(() => {
      createComponent();
    });

    it('has radio role for each icon option', () => {
      findIconLabels().wrappers.forEach((label) => {
        expect(label.attributes('role')).toBe('radio');
      });
    });

    it('has hidden radio inputs for each icon option', () => {
      const radioInputs = wrapper.findAllComponents(GlFormRadio);
      expect(radioInputs).toHaveLength(ICON_OPTIONS.length);

      radioInputs.wrappers.forEach((input) => {
        expect(input.classes()).toContain('gl-sr-only');
      });
    });

    it('displays screen reader text for selected icon', async () => {
      const secondIcon = findIconLabels().at(1);
      await secondIcon.trigger('click');

      const srText = wrapper.find('[aria-live="polite"]');
      expect(srText.exists()).toBe(true);
      expect(srText.text()).toBe(
        WI_TYPE_ICON_SELECTION_SET_SCREEN_READER_TEXT_MAP['work-item-epic'],
      );
    });
  });

  describe('edit mode with existing work item type', () => {
    it('preserves work item type data when editing', async () => {
      const workItemType = {
        name: 'Issue',
        iconName: 'work-item-issue',
      };

      createComponent({ isEditMode: true, workItemType });
      await nextTick();

      expect(findNameInput().attributes('value')).toBe('Issue');
    });

    it('displays correct icon in edit mode', async () => {
      const workItemType = {
        name: 'Task',
        iconName: 'work-item-task',
      };

      createComponent({ isEditMode: true, workItemType });
      await nextTick();

      const selectedIcon = findIconLabels().wrappers.find(
        (label) => label.attributes('aria-checked') === 'true',
      );
      expect(selectedIcon.attributes('aria-label')).toContain('Check');
    });

    it('allows changing icon in edit mode', async () => {
      const workItemType = {
        name: 'Type Name',
        iconName: 'work-item-task',
      };

      createComponent({ isEditMode: true, workItemType });
      await nextTick();

      const epicIcon = findIconLabels().at(1);
      await epicIcon.trigger('click');
      await nextTick();

      expect(epicIcon.attributes('aria-checked')).toBe('true');
    });
  });
});
