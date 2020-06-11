import { shallowMount } from '@vue/test-utils';
import { GlLink } from '@gitlab/ui';
import PinnedLinks from '~/issue_show/components/pinned_links.vue';

const plainZoomUrl = 'https://zoom.us/j/123456789';
const plainStatusUrl = 'https://status.com';

describe('PinnedLinks', () => {
  let wrapper;

  const findLinks = () => wrapper.findAll(GlLink);

  const createComponent = props => {
    wrapper = shallowMount(PinnedLinks, {
      propsData: {
        zoomMeetingUrl: '',
        publishedIncidentUrl: '',
        ...props,
      },
    });
  };

  it('displays Zoom link', () => {
    createComponent({
      zoomMeetingUrl: `<a href="${plainZoomUrl}">Zoom</a>`,
    });

    expect(
      findLinks()
        .at(0)
        .text(),
    ).toBe('Join Zoom meeting');
  });

  it('displays Status link', () => {
    createComponent({
      publishedIncidentUrl: `<a href="${plainStatusUrl}">Status</a>`,
    });

    expect(
      findLinks()
        .at(0)
        .text(),
    ).toBe('Published on status page');
  });

  it('does not render if there are no links', () => {
    createComponent({
      zoomMeetingUrl: '',
      publishedIncidentUrl: '',
    });

    expect(wrapper.find(GlLink).exists()).toBe(false);
  });
});
