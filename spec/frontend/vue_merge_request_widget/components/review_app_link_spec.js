import { shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import { mockTracking, triggerEvent } from 'helpers/tracking_helper';
import ReviewAppLink from '~/vue_merge_request_widget/components/review_app_link.vue';

describe('review app link', () => {
  const props = {
    link: '/review',
    cssClass: 'js-link',
    display: {
      text: 'View app',
      tooltip: '',
    },
  };
  let wrapper;

  beforeEach(() => {
    wrapper = shallowMount(ReviewAppLink, { propsData: props });
  });

  it('renders provided link as href attribute', () => {
    expect(wrapper.attributes('href')).toBe(props.link);
  });

  it('renders provided cssClass as class attribute', () => {
    expect(wrapper.classes('js-link')).toBe(true);
  });

  it('renders View app text', () => {
    expect(wrapper.text().trim()).toBe('View app');
  });

  it('renders svg icon', () => {
    expect(wrapper.find('svg')).not.toBeNull();
  });

  it('renders unsafe links', () => {
    expect(wrapper.findComponent(GlButton).props('isUnsafeLink')).toBe(true);
  });

  it('tracks an event when clicked', () => {
    const spy = mockTracking('_category_', wrapper.element, jest.spyOn);
    triggerEvent(wrapper.element);

    expect(spy).toHaveBeenCalledWith('_category_', 'open_review_app', {
      label: 'review_app',
    });
  });
});
