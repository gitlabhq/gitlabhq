import { GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { stubComponent } from 'helpers/stub_component';
import RunnerDeleteModal from '~/ci/runner/components/runner_delete_modal.vue';

describe('RunnerDeleteModal', () => {
  let wrapper;

  const findGlModal = () => wrapper.findComponent(GlModal);

  const createComponent = ({ props = {}, ...options } = {}, mountFn = shallowMount) => {
    wrapper = mountFn(RunnerDeleteModal, {
      attachTo: document.body,
      propsData: {
        runnerName: '#99 (AABBCCDD)',
        ...props,
      },
      attrs: {
        modalId: 'delete-runner-modal-99',
      },
      ...options,
    });
  };

  describe.each([null, 0, 1])('for %o runners', (managersCount) => {
    beforeEach(() => {
      createComponent({ props: { managersCount } });
    });

    it('Displays title', () => {
      expect(findGlModal().props('title')).toBe('Delete runner #99 (AABBCCDD)?');
    });

    it('Displays buttons', () => {
      expect(findGlModal().props('actionPrimary')).toMatchObject({
        text: 'Permanently delete runner',
      });
      expect(findGlModal().props('actionCancel')).toMatchObject({ text: 'Cancel' });
    });

    it('Displays contents', () => {
      expect(findGlModal().text()).toContain(
        'The runner will be permanently deleted and no longer available for projects or groups in the instance. Are you sure you want to continue?',
      );
    });
  });

  describe('for 2 runners', () => {
    beforeEach(() => {
      createComponent({ props: { managersCount: 2 } });
    });

    it('Displays title', () => {
      expect(findGlModal().props('title')).toBe('Delete 2 runners?');
    });

    it('Displays buttons', () => {
      expect(findGlModal().props('actionPrimary')).toMatchObject({
        text: 'Permanently delete 2 runners',
      });
      expect(findGlModal().props('actionCancel')).toMatchObject({ text: 'Cancel' });
    });

    it('Displays contents', () => {
      expect(findGlModal().text()).toContain(
        '2 runners will be permanently deleted and no longer available for projects or groups in the instance. Are you sure you want to continue?',
      );
    });
  });

  describe('Modal API', () => {
    let hideModalSpy;
    let showModalSpy;

    beforeEach(() => {
      hideModalSpy = jest.fn();
      showModalSpy = jest.fn();

      createComponent({
        stubs: {
          GlModal: stubComponent(GlModal, {
            methods: {
              hide: hideModalSpy,
              show: showModalSpy,
            },
          }),
        },
      });
    });

    it('When "show" method is called, modal is shown', () => {
      expect(showModalSpy).toHaveBeenCalledTimes(0);

      wrapper.vm.show();

      expect(showModalSpy).toHaveBeenCalledTimes(1);
    });

    it('When confirmed, modal gets hidden', () => {
      expect(hideModalSpy).toHaveBeenCalledTimes(0);

      findGlModal().vm.$emit('primary');

      expect(hideModalSpy).toHaveBeenCalledTimes(1);
    });
  });
});
