import { shallowMount } from '@vue/test-utils';
import { GlModal } from '@gitlab/ui';
import UpdateApplicationConfirmationModal from '~/clusters/components/update_application_confirmation_modal.vue';
import { ELASTIC_STACK } from '~/clusters/constants';

describe('UpdateApplicationConfirmationModal', () => {
  let wrapper;
  const appTitle = 'Elastic stack';

  const createComponent = (props = {}) => {
    wrapper = shallowMount(UpdateApplicationConfirmationModal, {
      propsData: { ...props },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  beforeEach(() => {
    createComponent({ application: ELASTIC_STACK, applicationTitle: appTitle });
  });

  it(`renders a modal with a title "Update ${appTitle}"`, () => {
    expect(wrapper.find(GlModal).attributes('title')).toEqual(`Update ${appTitle}`);
  });

  it(`renders a modal with an ok button labeled "Update ${appTitle}"`, () => {
    expect(wrapper.find(GlModal).attributes('ok-title')).toEqual(`Update ${appTitle}`);
  });

  describe('when ok button is clicked', () => {
    beforeEach(() => {
      wrapper.find(GlModal).vm.$emit('ok');
    });

    it('emits confirm event', () =>
      wrapper.vm.$nextTick().then(() => {
        expect(wrapper.emitted('confirm')).toBeTruthy();
      }));

    it('displays a warning text indicating the app will be updated', () => {
      expect(wrapper.text()).toContain(`You are about to update ${appTitle} on your cluster.`);
    });

    it('displays a custom warning text depending on the application', () => {
      expect(wrapper.text()).toContain(
        `Your Elasticsearch cluster will be re-created during this upgrade. Your logs will be re-indexed, and you will lose historical logs from hosts terminated in the last 30 days.`,
      );
    });
  });
});
