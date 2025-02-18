import { GlForm, GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DeleteButton from '~/projects/components/shared/delete_button.vue';
import DeleteModal from '~/projects/components/shared/delete_modal.vue';

jest.mock('~/lib/utils/csrf', () => ({ token: 'test-csrf-token' }));

describe('DeleteButton', () => {
  let wrapper;

  const findForm = () => wrapper.findComponent(GlForm);
  const findModal = () => wrapper.findComponent(DeleteModal);
  const findDeleteButton = () => wrapper.findComponent(GlButton);

  const defaultPropsData = {
    confirmPhrase: 'foo',
    formPath: 'some/path',
    isFork: false,
    issuesCount: 1,
    mergeRequestsCount: 2,
    forksCount: 3,
    starsCount: 4,
    nameWithNamespace: 'Foo / Bar',
  };

  const createComponent = (propsData) => {
    wrapper = shallowMountExtended(DeleteButton, {
      propsData: {
        ...defaultPropsData,
        ...propsData,
      },
      scopedSlots: {
        'modal-footer': '<div data-testid="modal-footer-slot"></div>',
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
    expect(wrapper.findComponent(GlButton).props('disabled')).toBe(false);
  });

  it('disables the button when the disabled prop is true', () => {
    createComponent({ disabled: true });
    expect(wrapper.findComponent(GlButton).props('disabled')).toBe(true);
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

  it('renders `modal-footer` slot', () => {
    createComponent();

    expect(wrapper.findByTestId('modal-footer-slot').exists()).toBe(true);
  });

  it('renders default text', () => {
    createComponent();

    const button = findDeleteButton();

    expect(button.text()).toBe('Delete project');
  });

  it('renders custom text', () => {
    createComponent({ buttonText: 'Delete project immediately' });

    const button = findDeleteButton();

    expect(button.text()).toBe('Delete project immediately');
  });
});
