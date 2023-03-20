import { mount } from '@vue/test-utils';
import { GlAlert, GlLink } from '@gitlab/ui';
import IncubationBanner from '~/google_cloud/components/incubation_banner.vue';

describe('google_cloud/components/incubation_banner', () => {
  let wrapper;

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findLinks = () => wrapper.findAllComponents(GlLink);
  const findFeatureRequestLink = () => findLinks().at(0);
  const findReportBugLink = () => findLinks().at(1);
  const findShareFeedbackLink = () => findLinks().at(2);

  beforeEach(() => {
    wrapper = mount(IncubationBanner);
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
      const expected =
        'https://gitlab.com/gitlab-org/incubation-engineering/five-minute-production/feedback/-/issues/new?issuable_template=feature_request';
      expect(link.text()).toBe('request a feature');
      expect(link.attributes('href')).toBe(expected);
    });

    it('contains report bug link', () => {
      const link = findReportBugLink();
      const expected =
        'https://gitlab.com/gitlab-org/incubation-engineering/five-minute-production/feedback/-/issues/new?issuable_template=report_bug';
      expect(link.text()).toBe('report a bug');
      expect(link.attributes('href')).toBe(expected);
    });

    it('contains share feedback link', () => {
      const link = findShareFeedbackLink();
      const expected =
        'https://gitlab.com/gitlab-org/incubation-engineering/five-minute-production/feedback/-/issues/new?issuable_template=general_feedback';
      expect(link.text()).toBe('share feedback');
      expect(link.attributes('href')).toBe(expected);
    });
  });
});
