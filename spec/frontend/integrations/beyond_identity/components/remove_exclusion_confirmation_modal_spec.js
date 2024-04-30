import { GlModal, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ConfirmRemovalModal from '~/integrations/beyond_identity/components/remove_exclusion_confirmation_modal.vue';

describe('ConfirmRemovalModal component', () => {
  let wrapper;
  const findModal = () => wrapper.findComponent(GlModal);

  const createComponent = () =>
    shallowMountExtended(ConfirmRemovalModal, {
      propsData: {
        visible: true,
        name: 'Some project',
        type: 'project',
      },
      stubs: { GlSprintf },
    });

  beforeEach(() => {
    wrapper = createComponent();
  });

  describe('default behavior', () => {
    it('renders a modal component', () => {
      expect(findModal().props()).toMatchObject({
        actionPrimary: { text: 'Remove exclusion', attributes: { variant: 'danger' } },
        actionSecondary: { text: 'Cancel', attributes: { category: 'secondary' } },
        modalId: 'confirm-remove-exclusion',
        title: 'Confirm project exclusion removal',
        visible: true,
      });
    });

    it('renders body content', () => {
      expect(findModal().text()).toBe(
        "You're removing an exclusion for Some project. Are you sure you want to continue?",
      );
    });
  });
});
