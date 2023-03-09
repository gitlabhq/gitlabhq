import { GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import DesignNoteSignedOut from '~/design_management/components/design_notes/design_note_signed_out.vue';

function createComponent(isAddDiscussion = false) {
  return shallowMount(DesignNoteSignedOut, {
    propsData: {
      registerPath: '/users/sign_up?redirect_to_referer=yes',
      signInPath: '/users/sign_in?redirect_to_referer=yes',
      isAddDiscussion,
    },
    stubs: {
      GlSprintf,
    },
  });
}

describe('DesignNoteSignedOut', () => {
  let wrapper;

  it('renders message containing register and sign-in links while user wants to reply to a discussion', () => {
    wrapper = createComponent();

    expect(wrapper.element).toMatchSnapshot();
  });

  it('renders message containing register and sign-in links while user wants to start a new discussion', () => {
    wrapper = createComponent(true);

    expect(wrapper.element).toMatchSnapshot();
  });
});
