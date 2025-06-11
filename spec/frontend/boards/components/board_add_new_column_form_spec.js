import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BoardAddNewColumnForm from '~/boards/components/board_add_new_column_form.vue';
import { mockLabelList } from '../mock_data';

describe('BoardAddNewColumnForm', () => {
  let wrapper;

  const mountComponent = ({ searchLabel = '', selectedIdValid = true, slots } = {}) => {
    wrapper = shallowMountExtended(BoardAddNewColumnForm, {
      propsData: {
        searchLabel,
        selectedIdValid,
      },
      slots,
    });
  };

  const formTitle = () => wrapper.findByTestId('board-add-column-form-title').text();
  const cancelButton = () => wrapper.findByTestId('cancelAddNewColumn');
  const submitButton = () => wrapper.findByTestId('addNewColumnButton');
  const formGroup = () => wrapper.findByTestId('boardValueDropdown');

  it('shows form title', () => {
    mountComponent();

    expect(formTitle()).toEqual(BoardAddNewColumnForm.i18n.newList);
  });

  it('clicking cancel hides the form', () => {
    mountComponent();

    cancelButton().vm.$emit('click');

    expect(wrapper.emitted('setAddColumnFormVisibility')).toEqual([[false]]);
  });

  describe('Add list button', () => {
    it('is enabled by default', () => {
      mountComponent();

      expect(submitButton().props('disabled')).toBe(false);
    });

    it('emits add-list event on click when an ID is selected', () => {
      mountComponent({
        selectedId: mockLabelList.label.id,
      });

      submitButton().vm.$emit('click');

      expect(wrapper.emitted('add-list')).toEqual([[]]);
    });
  });

  describe('Accessibility features', () => {
    it('shows form group in a valid state', () => {
      mountComponent();

      expect(formGroup().attributes('state')).toBe('true');
    });

    it('has the correct label-for attribute for the dropdown', () => {
      mountComponent({ searchLabel: 'Test Label' });

      expect(formGroup().attributes('label-for')).toBe('board-value-dropdown');
    });

    describe('when field is not valid', () => {
      beforeEach(() => {
        mountComponent({ selectedIdValid: false });
      });

      it('sets the correct form group state', () => {
        expect(formGroup().attributes('state')).toBeUndefined();
      });

      it('shows the correct invalid feedback message', () => {
        expect(formGroup().attributes('invalid-feedback')).toBe(
          BoardAddNewColumnForm.i18n.valueRequiredFieldFeedback,
        );
      });
    });
  });
});
