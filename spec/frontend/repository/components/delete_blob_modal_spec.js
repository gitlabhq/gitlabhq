import { GlFormTextarea, GlModal, GlFormInput, GlToggle } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import DeleteBlobModal from '~/repository/components/delete_blob_modal.vue';

jest.mock('~/lib/utils/csrf', () => ({ token: 'mock-csrf-token' }));

const initialProps = {
  modalId: 'Delete-blob',
  modalTitle: 'Delete File',
  deletePath: 'some/path',
  commitMessage: 'Delete File',
  targetBranch: 'some-target-branch',
  originalBranch: 'main',
  canPushCode: true,
  emptyRepo: false,
};

describe('DeleteBlobModal', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(DeleteBlobModal, {
      propsData: {
        ...initialProps,
        ...props,
      },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findForm = () => wrapper.findComponent({ ref: 'form' });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders Modal component', () => {
    createComponent();

    const { modalTitle: title } = initialProps;

    expect(findModal().props()).toMatchObject({
      title,
      size: 'md',
      actionPrimary: {
        text: 'Delete file',
      },
      actionCancel: {
        text: 'Cancel',
      },
    });
  });

  describe('form', () => {
    it('gets passed the path for action attribute', () => {
      createComponent();
      expect(findForm().attributes('action')).toBe(initialProps.deletePath);
    });

    it('submits the form', async () => {
      createComponent();

      const submitSpy = jest.spyOn(findForm().element, 'submit');
      findModal().vm.$emit('primary', { preventDefault: () => {} });
      await nextTick();

      expect(submitSpy).toHaveBeenCalled();
      submitSpy.mockRestore();
    });

    it.each`
      component         | defaultValue                  | canPushCode | targetBranch                 | originalBranch                 | exist
      ${GlFormTextarea} | ${initialProps.commitMessage} | ${true}     | ${initialProps.targetBranch} | ${initialProps.originalBranch} | ${true}
      ${GlFormInput}    | ${initialProps.targetBranch}  | ${true}     | ${initialProps.targetBranch} | ${initialProps.originalBranch} | ${true}
      ${GlFormInput}    | ${undefined}                  | ${false}    | ${initialProps.targetBranch} | ${initialProps.originalBranch} | ${false}
      ${GlToggle}       | ${'true'}                     | ${true}     | ${initialProps.targetBranch} | ${initialProps.originalBranch} | ${true}
      ${GlToggle}       | ${undefined}                  | ${true}     | ${'same-branch'}             | ${'same-branch'}               | ${false}
    `(
      'has the correct form fields ',
      ({ component, defaultValue, canPushCode, targetBranch, originalBranch, exist }) => {
        createComponent({
          canPushCode,
          targetBranch,
          originalBranch,
        });
        const formField = wrapper.findComponent(component);

        if (!exist) {
          expect(formField.exists()).toBe(false);
          return;
        }

        expect(formField.exists()).toBe(true);
        expect(formField.attributes('value')).toBe(defaultValue);
      },
    );

    it.each`
      input                     | value                          | emptyRepo | canPushCode | exist
      ${'authenticity_token'}   | ${'mock-csrf-token'}           | ${false}  | ${true}     | ${true}
      ${'authenticity_token'}   | ${'mock-csrf-token'}           | ${true}   | ${false}    | ${true}
      ${'_method'}              | ${'delete'}                    | ${false}  | ${true}     | ${true}
      ${'_method'}              | ${'delete'}                    | ${true}   | ${false}    | ${true}
      ${'original_branch'}      | ${initialProps.originalBranch} | ${false}  | ${true}     | ${true}
      ${'original_branch'}      | ${undefined}                   | ${true}   | ${true}     | ${false}
      ${'create_merge_request'} | ${'1'}                         | ${false}  | ${false}    | ${true}
      ${'create_merge_request'} | ${'1'}                         | ${false}  | ${true}     | ${true}
      ${'create_merge_request'} | ${undefined}                   | ${true}   | ${false}    | ${false}
    `(
      'passes $input as a hidden input with the correct value',
      ({ input, value, emptyRepo, canPushCode, exist }) => {
        createComponent({
          emptyRepo,
          canPushCode,
        });

        const inputMethod = findForm().find(`input[name="${input}"]`);

        if (!exist) {
          expect(inputMethod.exists()).toBe(false);
          return;
        }

        expect(inputMethod.attributes('type')).toBe('hidden');
        expect(inputMethod.attributes('value')).toBe(value);
      },
    );
  });
});
