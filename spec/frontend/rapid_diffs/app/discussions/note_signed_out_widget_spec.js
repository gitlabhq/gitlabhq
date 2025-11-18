import { shallowMount } from '@vue/test-utils';
import { GlLink, GlSprintf } from '@gitlab/ui';
import NoteSignedOutWidget from '~/rapid_diffs/app/discussions/note_signed_out_widget.vue';

describe('NoteSignedOutWidget', () => {
  let wrapper;

  const defaultProvisions = {
    endpoints: {
      register: 'register',
      signIn: 'signIn',
    },
  };

  const createComponent = () => {
    wrapper = shallowMount(NoteSignedOutWidget, {
      provide: defaultProvisions,
      stubs: { GlSprintf },
    });
  };

  it('shows signed out message', () => {
    createComponent();
    expect(wrapper.text()).toContain('Please register or sign in to reply');
  });

  it('shows register link', () => {
    createComponent();
    const link = wrapper
      .findAllComponents(GlLink)
      .filter((component) => component.text() === 'register')
      .at(0);
    expect(link.exists()).toBe(true);
    expect(link.attributes('href')).toBe(defaultProvisions.endpoints.register);
  });

  it('shows sign in link', () => {
    createComponent();
    const link = wrapper
      .findAllComponents(GlLink)
      .filter((component) => component.text() === 'sign in')
      .at(0);
    expect(link.exists()).toBe(true);
    expect(link.attributes('href')).toBe(defaultProvisions.endpoints.signIn);
  });
});
