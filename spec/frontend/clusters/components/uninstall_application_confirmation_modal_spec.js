import { shallowMount } from '@vue/test-utils';
import { GlModal } from '@gitlab/ui';
import UninstallApplicationConfirmationModal from '~/clusters/components/uninstall_application_confirmation_modal.vue';
import { INGRESS } from '~/clusters/constants';

describe('UninstallApplicationConfirmationModal', () => {
  let wrapper;
  const appTitle = 'Ingress';

  const createComponent = (props = {}) => {
    wrapper = shallowMount(UninstallApplicationConfirmationModal, {
      propsData: { ...props },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  beforeEach(() => {
    createComponent({ application: INGRESS, applicationTitle: appTitle });
  });

  it(`renders a modal with a title "Uninstall ${appTitle}"`, () => {
    expect(wrapper.find(GlModal).attributes('title')).toEqual(`Uninstall ${appTitle}`);
  });

  it(`renders a modal with an ok button labeled "Uninstall ${appTitle}"`, () => {
    expect(wrapper.find(GlModal).attributes('ok-title')).toEqual(`Uninstall ${appTitle}`);
  });

  describe('when ok button is clicked', () => {
    beforeEach(() => {
      jest.spyOn(wrapper.vm, 'trackUninstallButtonClick');
      wrapper.find(GlModal).vm.$emit('ok');
    });

    it('emits confirm event', () => {
      expect(wrapper.emitted('confirm')).toBeTruthy();
    });

    it('calls track uninstall button click mixin', () => {
      expect(wrapper.vm.trackUninstallButtonClick).toHaveBeenCalledWith(INGRESS);
    });
  });

  it('displays a warning text indicating the app will be uninstalled', () => {
    expect(wrapper.text()).toContain(`You are about to uninstall ${appTitle} from your cluster.`);
  });

  it('displays a custom warning text depending on the application', () => {
    expect(wrapper.text()).toContain(
      `The associated load balancer and IP will be deleted and cannot be restored.`,
    );
  });
});
