import { GlButton } from '@gitlab/ui';
import { shallowMount, RouterLinkStub } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import CloseButton from '~/design_management/components/toolbar/close_button.vue';
import { DESIGNS_ROUTE_NAME } from '~/design_management/router/constants';

describe('Design management toolbar close button', () => {
  let wrapper;

  function createComponent() {
    wrapper = shallowMount(CloseButton, {
      stubs: {
        RouterLink: RouterLinkStub,
      },
    });
  }

  it('links back to designs list', async () => {
    createComponent();

    await waitForPromises();

    expect(wrapper.findComponent(GlButton).attributes('to')).toBe(DESIGNS_ROUTE_NAME);
  });
});
