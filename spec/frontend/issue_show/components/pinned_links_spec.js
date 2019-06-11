import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlLink } from '@gitlab/ui';
import PinnedLinks from '~/issue_show/components/pinned_links.vue';

const localVue = createLocalVue();

const plainZoomUrl = 'https://zoom.us/j/123456789';
const vanityZoomUrl = 'https://gitlab.zoom.us/j/123456789';
const startZoomUrl = 'https://zoom.us/s/123456789';
const personalZoomUrl = 'https://zoom.us/my/hunter-zoloman';
const randomUrl = 'https://zoom.us.com';

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
    wrapper = shallowMount(localVue.extend(PinnedLinks), {
      localVue,
      sync: false,
      propsData: {
        descriptionHtml: '',
        ...props,
      },
    });
  };

  it('displays Zoom link', () => {
    createComponent({
      descriptionHtml: `<a href="${plainZoomUrl}">Zoom</a>`,
    });

    expect(link.text).toBe('Join Zoom meeting');
  });

  it('detects plain Zoom link', () => {
    createComponent({
      descriptionHtml: `<a href="${plainZoomUrl}">Zoom</a>`,
    });

    expect(link.href).toBe(plainZoomUrl);
  });

  it('detects vanity Zoom link', () => {
    createComponent({
      descriptionHtml: `<a href="${vanityZoomUrl}">Zoom</a>`,
    });

    expect(link.href).toBe(vanityZoomUrl);
  });

  it('detects Zoom start meeting link', () => {
    createComponent({
      descriptionHtml: `<a href="${startZoomUrl}">Zoom</a>`,
    });

    expect(link.href).toBe(startZoomUrl);
  });

  it('detects personal Zoom room link', () => {
    createComponent({
      descriptionHtml: `<a href="${personalZoomUrl}">Zoom</a>`,
    });

    expect(link.href).toBe(personalZoomUrl);
  });

  it('only renders final Zoom link in description', () => {
    createComponent({
      descriptionHtml: `<a href="${plainZoomUrl}">Zoom</a><a href="${vanityZoomUrl}">Zoom</a>`,
    });

    expect(link.href).toBe(vanityZoomUrl);
  });

  it('does not render for other links', () => {
    createComponent({
      descriptionHtml: `<a href="${randomUrl}">Some other link</a>`,
    });

    expect(wrapper.find(GlLink).exists()).toBe(false);
  });
});
