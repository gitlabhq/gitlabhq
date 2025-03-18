import { GlModal } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RemoveAutopopulatedEntriesModal from '~/token_access/components/remove_autopopulated_entries_modal.vue';

const projectName = 'My project';
const fullPath = 'root/my-repo';

Vue.use(VueApollo);

describe('RemoveAutopopulatedEntriesModal component', () => {
  let wrapper;

  const findModal = () => wrapper.findComponent(GlModal);

  const createComponent = ({ props } = {}) => {
    wrapper = shallowMountExtended(RemoveAutopopulatedEntriesModal, {
      provide: {
        fullPath,
      },
      propsData: {
        projectName,
        showModal: true,
        ...props,
      },
    });
  };

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it.each`
      modalEvent     | emittedEvent
      ${'canceled'}  | ${'hide'}
      ${'hidden'}    | ${'hide'}
      ${'secondary'} | ${'hide'}
    `(
      'emits the $emittedEvent event when $modalEvent event is triggered',
      ({ modalEvent, emittedEvent }) => {
        expect(wrapper.emitted(emittedEvent)).toBeUndefined();

        findModal().vm.$emit(modalEvent);

        expect(wrapper.emitted(emittedEvent)).toHaveLength(1);
      },
    );
  });

  describe('when clicking on the primary button', () => {
    it('emits the remove-entries event', () => {
      createComponent();

      expect(wrapper.emitted('remove-entries')).toBeUndefined();

      findModal().vm.$emit('primary', { preventDefault: jest.fn() });

      expect(wrapper.emitted('remove-entries')).toHaveLength(1);
    });
  });
});
