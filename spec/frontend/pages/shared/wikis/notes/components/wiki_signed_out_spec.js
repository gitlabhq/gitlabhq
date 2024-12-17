import { GlSprintf, GlLink } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WikiDiscussionsSignedOut from '~/pages/shared/wikis/wiki_notes/components/wiki_discussions_signed_out.vue';

describe('WikiSignedOut', () => {
  let wrapper;

  const createWrapper = ({ props } = {}) =>
    shallowMountExtended(WikiDiscussionsSignedOut, {
      propsData: {
        isReply: false,
        ...props,
      },
      provide: {
        registerPath: '/register',
        signInPath: '/signin',
      },
      stubs: {
        GlSprintf,
        GlLink,
      },
    });

  beforeEach(() => {
    wrapper = createWrapper();
  });

  it('should render the content correctly when reply is false', () => {
    expect(wrapper.element.textContent).toBe('Please register or sign in to add a comment.');
  });

  it('should render content correctly when reply is true', async () => {
    wrapper = createWrapper({
      props: {
        isReply: true,
      },
    });

    await nextTick();
    expect(wrapper.element.textContent).toBe('Please register or sign in to reply.');
  });

  it('should render correct link for signin', () => {
    const link = wrapper.findByText('sign in');

    expect(link.attributes('href')).toBe('/signin');
  });

  it('should render correct link for registration', () => {
    const link = wrapper.findByText('register');

    expect(link.attributes('href')).toBe('/register');
  });
});
