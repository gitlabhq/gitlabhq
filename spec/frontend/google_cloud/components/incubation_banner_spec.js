import { mount } from '@vue/test-utils';
import { GlAlert, GlLink } from '@gitlab/ui';
import IncubationBanner from '~/google_cloud/components/incubation_banner.vue';

describe('IncubationBanner component', () => {
  let wrapper;

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findLinks = () => wrapper.findAllComponents(GlLink);
  const findFeatureRequestLink = () => findLinks().at(0);
  const findReportBugLink = () => findLinks().at(1);
  const findShareFeedbackLink = () => findLinks().at(2);

  beforeEach(() => {
    const propsData = {
      shareFeedbackUrl: 'url_general_feedback',
      reportBugUrl: 'url_report_bug',
      featureRequestUrl: 'url_feature_request',
    };
    wrapper = mount(IncubationBanner, { propsData });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('contains alert', () => {
    expect(findAlert().exists()).toBe(true);
  });

  it('contains relevant text', () => {
    expect(findAlert().text()).toContain(
      'This is an experimental feature developed by GitLab Incubation Engineering.',
    );
  });

  describe('has relevant gl-links', () => {
    it('three in total', () => {
      expect(findLinks().length).toBe(3);
    });

    it('contains feature request link', () => {
      const link = findFeatureRequestLink();
      expect(link.text()).toBe('request a feature');
      expect(link.attributes('href')).toBe('url_feature_request');
    });

    it('contains report bug link', () => {
      const link = findReportBugLink();
      expect(link.text()).toBe('report a bug');
      expect(link.attributes('href')).toBe('url_report_bug');
    });

    it('contains share feedback link', () => {
      const link = findShareFeedbackLink();
      expect(link.text()).toBe('share feedback');
      expect(link.attributes('href')).toBe('url_general_feedback');
    });
  });
});
