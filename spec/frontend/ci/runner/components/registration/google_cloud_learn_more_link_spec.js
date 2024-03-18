import { GlIcon, GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import GoogleCloudLearnMoreLink from '~/ci/runner/components/registration/google_cloud_learn_more_link.vue';

describe('GoogleCloudRegistrationInstructions', () => {
  let wrapper;

  const findLink = () => wrapper.findComponent(GlLink);

  const createComponent = () => {
    wrapper = shallowMountExtended(GoogleCloudLearnMoreLink, {
      propsData: {
        href: 'www.example.com/docs',
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders expected text', () => {
    expect(wrapper.text()).toBe('Learn more in the Google Cloud documentation.');
  });

  it('renders link', () => {
    expect(findLink().props('target')).toBe('_blank');
    expect(findLink().attributes('href')).toBe('www.example.com/docs');

    expect(findLink().text()).toBe('Google Cloud documentation');
    expect(findLink().findComponent(GlIcon).props('name')).toBe('external-link');
  });
});
