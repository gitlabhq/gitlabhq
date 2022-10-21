import { GlModal } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import RunnerDeleteModal from '~/ci/runner/components/runner_delete_modal.vue';

describe('RunnerDeleteModal', () => {
  let wrapper;

  const findGlModal = () => wrapper.findComponent(GlModal);

  const createComponent = ({ props = {} } = {}, mountFn = shallowMount) => {
    wrapper = mountFn(RunnerDeleteModal, {
      attachTo: document.body,
      propsData: {
        runnerName: '#99 (AABBCCDD)',
        ...props,
      },
      attrs: {
        modalId: 'delete-runner-modal-99',
      },
    });
  };

  it('Displays title', () => {
    createComponent();

    expect(findGlModal().props('title')).toBe('Delete runner #99 (AABBCCDD)?');
  });

  it('Displays buttons', () => {
    createComponent();

    expect(findGlModal().props('actionPrimary')).toMatchObject({ text: 'Delete runner' });
    expect(findGlModal().props('actionCancel')).toMatchObject({ text: 'Cancel' });
  });

  it('Displays contents', () => {
    createComponent();

    expect(findGlModal().html()).toContain(
      'The runner will be permanently deleted and no longer available for projects or groups in the instance. Are you sure you want to continue?',
    );
  });

  describe('When modal is confirmed by the user', () => {
    let hideModalSpy;

    beforeEach(() => {
      createComponent({}, mount);
      hideModalSpy = jest.spyOn(wrapper.vm.$refs.modal, 'hide').mockImplementation(() => {});
    });

    it('Modal gets hidden', () => {
      expect(hideModalSpy).toHaveBeenCalledTimes(0);

      findGlModal().vm.$emit('primary');

      expect(hideModalSpy).toHaveBeenCalledTimes(1);
    });
  });
});
