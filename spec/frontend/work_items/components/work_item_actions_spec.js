import { GlDropdownDivider, GlModal } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemActions from '~/work_items/components/work_item_actions.vue';

const TEST_ID_CONFIDENTIALITY_TOGGLE_ACTION = 'confidentiality-toggle-action';
const TEST_ID_DELETE_ACTION = 'delete-action';

describe('WorkItemActions component', () => {
  let wrapper;
  let glModalDirective;

  const findModal = () => wrapper.findComponent(GlModal);
  const findConfidentialityToggleButton = () =>
    wrapper.findByTestId(TEST_ID_CONFIDENTIALITY_TOGGLE_ACTION);
  const findDeleteButton = () => wrapper.findByTestId(TEST_ID_DELETE_ACTION);
  const findDropdownItems = () => wrapper.findAll('[data-testid="work-item-actions-dropdown"] > *');
  const findDropdownItemsActual = () =>
    findDropdownItems().wrappers.map((x) => {
      if (x.is(GlDropdownDivider)) {
        return { divider: true };
      }

      return {
        testId: x.attributes('data-testid'),
        text: x.text(),
      };
    });

  const createComponent = ({
    canUpdate = true,
    canDelete = true,
    isConfidential = false,
    isParentConfidential = false,
  } = {}) => {
    glModalDirective = jest.fn();
    wrapper = shallowMountExtended(WorkItemActions, {
      propsData: {
        workItemId: '123',
        canUpdate,
        canDelete,
        isConfidential,
        isParentConfidential,
        workItemType: 'Task',
      },
      directives: {
        glModal: {
          bind(_, { value }) {
            glModalDirective(value);
          },
        },
      },
    });
  };

  it('renders modal', () => {
    createComponent();

    expect(findModal().exists()).toBe(true);
    expect(findModal().props('visible')).toBe(false);
  });

  it('renders dropdown actions', () => {
    createComponent();

    expect(findDropdownItemsActual()).toEqual([
      {
        testId: TEST_ID_CONFIDENTIALITY_TOGGLE_ACTION,
        text: 'Turn on confidentiality',
      },
      {
        divider: true,
      },
      {
        testId: TEST_ID_DELETE_ACTION,
        text: 'Delete task',
      },
    ]);
  });

  describe('toggle confidentiality action', () => {
    it.each`
      isConfidential | buttonText
      ${true}        | ${'Turn off confidentiality'}
      ${false}       | ${'Turn on confidentiality'}
    `(
      'renders confidentiality toggle button with text "$buttonText"',
      ({ isConfidential, buttonText }) => {
        createComponent({ isConfidential });

        expect(findConfidentialityToggleButton().text()).toBe(buttonText);
      },
    );

    it('emits `toggleWorkItemConfidentiality` event when clicked', () => {
      createComponent();

      findConfidentialityToggleButton().vm.$emit('click');

      expect(wrapper.emitted('toggleWorkItemConfidentiality')[0]).toEqual([true]);
    });

    it.each`
      props                             | propName                  | value
      ${{ isParentConfidential: true }} | ${'isParentConfidential'} | ${true}
      ${{ canUpdate: false }}           | ${'canUpdate'}            | ${false}
    `('does not render when $propName is $value', ({ props }) => {
      createComponent(props);

      expect(findConfidentialityToggleButton().exists()).toBe(false);
    });
  });

  describe('delete action', () => {
    it('shows confirm modal when clicked', () => {
      createComponent();

      findDeleteButton().vm.$emit('click');

      expect(glModalDirective).toHaveBeenCalled();
    });

    it('emits event when clicking OK button', () => {
      createComponent();

      findModal().vm.$emit('ok');

      expect(wrapper.emitted('deleteWorkItem')).toEqual([[]]);
    });

    it('does not render when canDelete is false', () => {
      createComponent({
        canDelete: false,
      });

      expect(findDeleteButton().exists()).toBe(false);
      expect(wrapper.findComponent(GlDropdownDivider).exists()).toBe(false);
    });
  });
});
