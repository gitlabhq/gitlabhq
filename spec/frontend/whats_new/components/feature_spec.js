import { shallowMount } from '@vue/test-utils';
import timezoneMock from 'timezone-mock';
import { GlTruncate, GlDrawer, GlButton } from '@gitlab/ui';
import { nextTick } from 'vue';
import Feature from '~/whats_new/components/feature.vue';
import { DOCS_URL_IN_EE_DIR } from 'jh_else_ce/lib/utils/url_utility';
import { mockTracking, unmockTracking, triggerEvent } from 'helpers/tracking_helper';

describe("What's new single feature", () => {
  /** @type {import("@vue/test-utils").Wrapper} */
  let wrapper;
  let trackingSpy;

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

  const findFeatureNameLink = () => wrapper.find('[data-testid="whats-new-item-link"]');
  const findReleaseDate = () => wrapper.find('[data-testid="release-date"]');
  const findBodyAnchor = () => wrapper.find('[data-testid="body-content"] a');
  const findImageLink = () => wrapper.find('[data-testid="whats-new-image-link"]');
  const findTruncatedDescription = () => wrapper.findComponent(GlTruncate);
  const findDrawerToggle = () => wrapper.find('[data-testid="whats-new-article-toggle"]');
  const findDrawerCloseButton = () => wrapper.find('[data-testid="whats-new-article-close"]');
  const findUnreadArticleIcon = () => wrapper.find('[data-testid="unread-article-icon"]');

  const createWrapper = ({ feature, showUnread = false } = {}) => {
    wrapper = shallowMount(Feature, {
      propsData: { feature, showUnread },
      stubs: { GlDrawer, GlButton },
    });
  };

  describe('with article drawer', () => {
    beforeEach(() => {
      createWrapper({ feature: exampleFeature });
      findDrawerToggle().trigger('click');
    });

    afterEach(() => {
      if (trackingSpy) {
        unmockTracking();
        trackingSpy = null;
      }
    });

    it('renders the date', () => {
      expect(findReleaseDate().text()).toBe('Apr 22, 2021');
    });

    it('renders image link', () => {
      expect(findImageLink().exists()).toBe(true);
      expect(findImageLink().find('div').attributes('style')).toBe(
        `background-image: url(${exampleFeature.image_url});`,
      );
    });

    describe('when published_at is null', () => {
      it('does not render the date', () => {
        createWrapper({ feature: { ...exampleFeature, published_at: null } });

        findDrawerToggle().trigger('click');

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
        expect(findReleaseDate().text()).toBe('Apr 22, 2021');
      });
    });

    describe('when image_url is null', () => {
      it('does not render image link', () => {
        createWrapper({ feature: { ...exampleFeature, image_url: null } });

        findDrawerToggle().trigger('click');

        expect(findImageLink().exists()).toBe(false);
      });
    });

    it('safe-html config allows target attribute on elements', () => {
      expect(findBodyAnchor().attributes()).toEqual({
        href: expect.any(String),
        rel: 'noopener noreferrer',
        target: '_blank',
      });
    });

    it('send an event when feature item is clicked', () => {
      trackingSpy = mockTracking('_category_', wrapper.element, jest.spyOn);

      triggerEvent(findFeatureNameLink().element);

      expect(trackingSpy.mock.calls[0]).toMatchObject([
        '_category_',
        'click_whats_new_item',
        {
          label: 'Compliance pipeline configurations',
          property: `${DOCS_URL_IN_EE_DIR}/user/project/settings/#compliance-pipeline-configuration`,
        },
      ]);
    });
  });

  describe('when the item to render is release heading', () => {
    it('renders the first major release correctly', () => {
      createWrapper({ feature: { releaseHeading: true, release: 18 } });

      expect(wrapper.find('h5').text()).toBe('18.0 Release');
    });

    it('renders other release correctly', () => {
      createWrapper({ feature: { releaseHeading: true, release: 18.11 } });

      expect(wrapper.find('h5').text()).toBe('18.11 Release');
    });

    it('renders "Other updates" when no release is provided', () => {
      createWrapper({ feature: { releaseHeading: true, release: undefined } });

      expect(wrapper.find('h5').text()).toBe('Other updates');
    });
  });

  it('renders the drawer toggle only initially', () => {
    createWrapper({ feature: exampleFeature });

    expect(findDrawerToggle().text()).toContain('Compliance pipeline configurations');
    expect(findTruncatedDescription().exists()).toBe(true);
    expect(findImageLink().exists()).toBe(false);
  });

  describe('with showUnread', () => {
    it('does not render the unread icon when showUnread is false', () => {
      createWrapper({ feature: exampleFeature });

      expect(findUnreadArticleIcon().exists()).toBe(false);
    });

    it('does not emit mark-article-as-read event when showUnread is false', () => {
      createWrapper({ feature: exampleFeature });

      findDrawerToggle().trigger('click');

      expect(wrapper.emitted('mark-article-as-read')).toBeUndefined();
    });

    it('renders the unread icon when showUnread is true', () => {
      createWrapper({ feature: exampleFeature, showUnread: true });

      expect(findUnreadArticleIcon().exists()).toBe(true);
    });

    it('emits mark-article-as-read event when the drawer toggle is clicked', () => {
      createWrapper({ feature: exampleFeature, showUnread: true });

      findDrawerToggle().trigger('click');

      expect(wrapper.emitted('mark-article-as-read')).toHaveLength(1);
    });
  });

  it('closes the drawer when the back button in the header is clicked', async () => {
    createWrapper({ feature: exampleFeature });

    findDrawerToggle().trigger('click');

    await nextTick();

    expect(findImageLink().exists()).toBe(true);

    findDrawerCloseButton().trigger('click');

    await nextTick();

    expect(findImageLink().exists()).toBe(false);
  });
});
