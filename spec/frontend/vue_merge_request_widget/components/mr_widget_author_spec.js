import { shallowMount } from '@vue/test-utils';
import { GlAvatar } from '@gitlab/ui';
import { nextTick } from 'vue';
import MrWidgetAuthor from '~/vue_merge_request_widget/components/mr_widget_author.vue';

window.gl = window.gl || {};

describe('MrWidgetAuthor', () => {
  let wrapper;
  let oldWindowGl;
  const mockAuthor = {
    name: 'Administrator',
    username: 'root',
    webUrl: 'http://localhost:3000/root',
    avatarUrl: 'http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
  };

  beforeEach(() => {
    oldWindowGl = window.gl;
    window.gl = {
      mrWidgetData: {
        defaultAvatarUrl: 'no_avatar.png',
      },
    };
    wrapper = shallowMount(MrWidgetAuthor, {
      propsData: {
        author: mockAuthor,
      },
    });
  });

  afterEach(() => {
    window.gl = oldWindowGl;
  });

  it('renders link with the author web url', () => {
    expect(wrapper.attributes('href')).toBe('http://localhost:3000/root');
  });

  it('renders image with avatar url', () => {
    expect(wrapper.findComponent(GlAvatar).props('src')).toBe(
      'http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
    );
  });

  it('renders image with default avatar url when no avatarUrl is present in author', async () => {
    wrapper.setProps({
      author: {
        ...mockAuthor,
        avatarUrl: null,
      },
    });

    await nextTick();

    expect(wrapper.findComponent(GlAvatar).props('src')).toBe('no_avatar.png');
  });

  it('renders author name', () => {
    expect(wrapper.find('span').text()).toBe('Administrator');
  });
});
