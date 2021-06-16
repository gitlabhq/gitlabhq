import { shallowMount } from '@vue/test-utils';
import Feature from '~/whats_new/components/feature.vue';

describe("What's new single feature", () => {
  /** @type {import("@vue/test-utils").Wrapper} */
  let wrapper;

  const exampleFeature = {
    title: 'Compliance pipeline configurations',
    body:
      '<p data-testid="body-content">We are thrilled to announce that it is now possible to define enforceable pipelines that will run for any project assigned a corresponding <a href="https://en.wikipedia.org/wiki/Compliance_(psychology)" target="_blank" rel="noopener noreferrer" onload="alert(xss)">compliance</a> framework.</p>',
    stage: 'Manage',
    'self-managed': true,
    'gitlab-com': true,
    packages: ['Ultimate'],
    url: 'https://docs.gitlab.com/ee/user/project/settings/#compliance-pipeline-configuration',
    image_url: 'https://img.youtube.com/vi/upLJ_equomw/hqdefault.jpg',
    published_at: '2021-04-22T00:00:00.000Z',
    release: '13.11',
  };

  const findReleaseDate = () => wrapper.find('[data-testid="release-date"]');
  const findBodyAnchor = () => wrapper.find('[data-testid="body-content"] a');

  const createWrapper = ({ feature } = {}) => {
    wrapper = shallowMount(Feature, {
      propsData: { feature },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders the date', () => {
    createWrapper({ feature: exampleFeature });
    expect(findReleaseDate().text()).toBe('April 22, 2021');
  });

  describe('when the published_at is null', () => {
    it("doesn't render the date", () => {
      createWrapper({ feature: { ...exampleFeature, published_at: null } });
      expect(findReleaseDate().exists()).toBe(false);
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
