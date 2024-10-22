import { shallowMount } from '@vue/test-utils';
import timezoneMock from 'timezone-mock';
import Feature from '~/whats_new/components/feature.vue';
import { DOCS_URL_IN_EE_DIR } from 'jh_else_ce/lib/utils/url_utility';

describe("What's new single feature", () => {
  /** @type {import("@vue/test-utils").Wrapper} */
  let wrapper;

  const exampleFeature = {
    name: 'Compliance pipeline configurations',
    description:
      '<p data-testid="body-content">We are thrilled to announce that it is now possible to define enforceable pipelines that will run for any project assigned a corresponding <a href="https://en.wikipedia.org/wiki/Compliance_(psychology)" target="_blank" rel="noopener noreferrer" onload="alert(xss)">compliance</a> framework.</p>',
    stage: 'Manage',
    'self-managed': true,
    'gitlab-com': true,
    available_in: ['Ultimate'],
    documentation_link: `${DOCS_URL_IN_EE_DIR}/user/project/settings/#compliance-pipeline-configuration`,
    image_url: 'https://img.youtube.com/vi/upLJ_equomw/hqdefault.jpg',
    published_at: '2021-04-22',
    release: '13.11',
  };

  const findReleaseDate = () => wrapper.find('[data-testid="release-date"]');
  const findBodyAnchor = () => wrapper.find('[data-testid="body-content"] a');
  const findImageLink = () => wrapper.find('[data-testid="whats-new-image-link"]');

  const createWrapper = ({ feature } = {}) => {
    wrapper = shallowMount(Feature, {
      propsData: { feature },
    });
  };

  it('renders the date', () => {
    createWrapper({ feature: exampleFeature });

    expect(findReleaseDate().text()).toBe('Apr 22, 2021');
  });

  it('renders image link', () => {
    createWrapper({ feature: exampleFeature });

    expect(findImageLink().exists()).toBe(true);
    expect(findImageLink().find('div').attributes('style')).toBe(
      `background-image: url(${exampleFeature.image_url});`,
    );
  });

  describe('when published_at is null', () => {
    it('does not render the date', () => {
      createWrapper({ feature: { ...exampleFeature, published_at: null } });

      expect(findReleaseDate().exists()).toBe(false);
    });
  });

  describe('when the user is in a time zone West of UTC', () => {
    beforeEach(() => {
      timezoneMock.register('US/Pacific');
    });

    afterEach(() => {
      timezoneMock.unregister();
    });

    it('renders the date', () => {
      createWrapper({ feature: exampleFeature });

      expect(findReleaseDate().text()).toBe('Apr 22, 2021');
    });
  });

  describe('when image_url is null', () => {
    it('does not render image link', () => {
      createWrapper({ feature: { ...exampleFeature, image_url: null } });

      expect(findImageLink().exists()).toBe(false);
    });
  });

  it('safe-html config allows target attribute on elements', () => {
    createWrapper({ feature: exampleFeature });

    expect(findBodyAnchor().attributes()).toEqual({
      href: expect.any(String),
      rel: 'noopener noreferrer',
      target: '_blank',
    });
  });
});
