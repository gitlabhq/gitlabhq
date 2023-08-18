import { GlForm, GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DeleteButton from '~/projects/components/shared/delete_button.vue';
import DeleteModal from '~/projects/components/shared/delete_modal.vue';

jest.mock('~/lib/utils/csrf', () => ({ token: 'test-csrf-token' }));

describe('DeleteButton', () => {
  let wrapper;

  const findForm = () => wrapper.findComponent(GlForm);
  const findModal = () => wrapper.findComponent(DeleteModal);

  const defaultPropsData = {
    confirmPhrase: 'foo',
    formPath: 'some/path',
    isFork: false,
    issuesCount: 1,
    mergeRequestsCount: 2,
    forksCount: 3,
    starsCount: 4,
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

  describe('when button is clicked', () => {
    beforeEach(() => {
      createComponent();
      wrapper.findComponent(GlButton).vm.$emit('click');
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
});
