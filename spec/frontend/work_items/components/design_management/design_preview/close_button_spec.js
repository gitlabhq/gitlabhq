import { GlButton } from '@gitlab/ui';
import { shallowMount, RouterLinkStub } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import CloseButton from '~/work_items/components/design_management/design_preview/close_button.vue';
import { ROUTES } from '~/work_items/constants';

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

    expect(wrapper.findComponent(GlButton).attributes('to')).toEqual(ROUTES.workItem);
  });
});
