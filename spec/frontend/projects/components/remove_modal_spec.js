import { shallowMount } from '@vue/test-utils';
import { GlButton, GlModal } from '@gitlab/ui';
import ProjectRemoveModal from '~/projects/components/remove_modal.vue';

describe('Project remove modal', () => {
  let wrapper;

  const findFormElement = () => wrapper.find('form').element;
  const findConfirmButton = () => wrapper.find(GlModal).find(GlButton);

  const defaultProps = {
    formPath: 'some/path',
    confirmPhrase: 'foo',
    warningMessage: 'This can lead to data loss.',
  };

  const createComponent = (data = {}) => {
    wrapper = shallowMount(ProjectRemoveModal, {
      propsData: defaultProps,
      data: () => data,
      stubs: {
        GlButton,
        GlModal,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('initialized', () => {
    beforeEach(() => {
      createComponent();
    });

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('user input matches the confirmPhrase', () => {
    beforeEach(() => {
      createComponent({ userInput: defaultProps.confirmPhrase });
    });

    it('the confirm button is not dislabled', () => {
      expect(findConfirmButton().attributes('disabled')).toBe(undefined);
    });

    describe('and when the confirmation button is clicked', () => {
      beforeEach(() => {
        findConfirmButton().vm.$emit('click');
      });

      it('submits the form element', () => {
        expect(findFormElement().submit).toHaveBeenCalled();
      });
    });
  });
});
