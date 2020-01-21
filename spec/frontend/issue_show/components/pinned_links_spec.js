import { shallowMount } from '@vue/test-utils';
import { GlLink } from '@gitlab/ui';
import PinnedLinks from '~/issue_show/components/pinned_links.vue';

const plainZoomUrl = 'https://zoom.us/j/123456789';

describe('PinnedLinks', () => {
  let wrapper;

  const link = {
    get text() {
      return wrapper.find(GlLink).text();
    },
    get href() {
      return wrapper.find(GlLink).attributes('href');
    },
  };

  const createComponent = props => {
    wrapper = shallowMount(PinnedLinks, {
      propsData: {
        zoomMeetingUrl: null,
        ...props,
      },
    });
  };

  it('displays Zoom link', () => {
    createComponent({
      zoomMeetingUrl: `<a href="${plainZoomUrl}">Zoom</a>`,
    });

    expect(link.text).toBe('Join Zoom meeting');
  });

  it('does not render if there are no links', () => {
    createComponent({
      zoomMeetingUrl: null,
    });

    expect(wrapper.find(GlLink).exists()).toBe(false);
  });
});
