import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import PinnedLinks from '~/issues/show/components/pinned_links.vue';
import { STATUS_PAGE_PUBLISHED, JOIN_ZOOM_MEETING } from '~/issues/show/constants';

const plainZoomUrl = 'https://zoom.us/j/123456789';
const plainStatusUrl = 'https://status.com';

describe('PinnedLinks', () => {
  let wrapper;

  const findButtons = () => wrapper.findAllComponents(GlButton);

  const createComponent = (props) => {
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

    expect(findButtons().at(0).text()).toBe(JOIN_ZOOM_MEETING);
  });

  it('displays Status link', () => {
    createComponent({
      publishedIncidentUrl: `<a href="${plainStatusUrl}">Status</a>`,
    });

    expect(findButtons().at(0).text()).toBe(STATUS_PAGE_PUBLISHED);
  });

  it('does not render if there are no links', () => {
    createComponent({
      zoomMeetingUrl: '',
      publishedIncidentUrl: '',
    });

    expect(findButtons()).toHaveLength(0);
  });
});
