import { GlForm, GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DeleteButton from '~/groups/components/delete_button.vue';
import DeleteModal from '~/groups/components/delete_modal.vue';

jest.mock('~/lib/utils/csrf', () => ({ token: 'test-csrf-token' }));

describe('DeleteButton', () => {
  let wrapper;

  const findForm = () => wrapper.findComponent(GlForm);
  const findModal = () => wrapper.findComponent(DeleteModal);
  const findDeleteButton = () => wrapper.findComponent(GlButton);

  const defaultPropsData = {
    confirmPhrase: 'acme/my-group',
    formPath: 'some/path',
    subgroupsCount: 1,
    projectsCount: 2,
    fullName: 'Foo / Bar',
    markedForDeletion: false,
    permanentDeletionDate: '2025-11-28',
  };

  const createComponent = (propsData) => {
    wrapper = shallowMountExtended(DeleteButton, {
      propsData: {
        ...defaultPropsData,
        ...propsData,
      },
    });
  };

  it('renders modal and passes correct props', () => {
    createComponent();

    const { formPath, ...expectedProps } = defaultPropsData;

    expect(findModal().props()).toMatchObject({
      visible: false,
      ...expectedProps,
    });
  });

  it('renders form with required inputs', () => {
    createComponent();

    const form = findForm();

    expect(form.find('input[name="_method"]').attributes('value')).toBe('delete');
    expect(form.find('input[name="authenticity_token"]').attributes('value')).toBe(
      'test-csrf-token',
    );
  });

  it('renders the button', () => {
    createComponent();
    expect(wrapper.findComponent(GlButton).exists()).toBe(true);
  });

  describe('when button is clicked', () => {
    beforeEach(() => {
      createComponent();
      findDeleteButton().vm.$emit('click');
    });

    it('opens modal', () => {
      expect(findModal().props('visible')).toBe(true);
    });
  });

  describe('when modal emits `primary` event', () => {
    it('submits the form', () => {
      createComponent();

      const submitMock = jest.fn();

      findForm().element.submit = submitMock;

      findModal().vm.$emit('primary');

      expect(submitMock).toHaveBeenCalled();
    });
  });

  describe('when markedForDeletion prop is false', () => {
    it('renders Delete as button text', () => {
      createComponent();

      const button = findDeleteButton();

      expect(button.text()).toBe('Delete');
    });

    it('does not render permanently_remove=true hidden input', () => {
      createComponent();

      expect(findForm().find('input[name="permanently_remove"]').exists()).toBe(false);
    });
  });

  describe('when markedForDeletion prop is true', () => {
    beforeEach(() => {
      createComponent({ markedForDeletion: true });
    });

    it('renders Delete permanently as button text', () => {
      const button = findDeleteButton();

      expect(button.text()).toBe('Delete permanently');
    });

    it('renders permanently_remove=true hidden input', () => {
      expect(findForm().find('input[name="permanently_remove"]').attributes('value')).toBe('true');
    });
  });
});
