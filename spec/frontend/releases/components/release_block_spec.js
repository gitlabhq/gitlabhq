import $ from 'jquery';
import { mount } from '@vue/test-utils';
import EvidenceBlock from '~/releases/components/evidence_block.vue';
import ReleaseBlock from '~/releases/components/release_block.vue';
import ReleaseBlockFooter from '~/releases/components/release_block_footer.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { release as originalRelease } from '../mock_data';
import Icon from '~/vue_shared/components/icon.vue';
import * as commonUtils from '~/lib/utils/common_utils';
import { BACK_URL_PARAM } from '~/releases/constants';
import * as urlUtility from '~/lib/utils/url_utility';

describe('Release block', () => {
  let wrapper;
  let release;

  const factory = (releaseProp, featureFlags = {}) => {
    wrapper = mount(ReleaseBlock, {
      propsData: {
        release: releaseProp,
      },
      provide: {
        glFeatures: {
          releaseIssueSummary: true,
          ...featureFlags,
        },
      },
    });

    return wrapper.vm.$nextTick();
  };

  const milestoneListLabel = () => wrapper.find('.js-milestone-list-label');
  const editButton = () => wrapper.find('.js-edit-button');

  beforeEach(() => {
    jest.spyOn($.fn, 'renderGFM');
    release = commonUtils.convertObjectPropsToCamelCase(originalRelease, { deep: true });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('with default props', () => {
    beforeEach(() => factory(release));

    it("renders the block with an id equal to the release's tag name", () => {
      expect(wrapper.attributes().id).toBe('v0.3');
    });

    it(`renders an edit button that links to the "Edit release" page with a "${BACK_URL_PARAM}" parameter`, () => {
      expect(editButton().exists()).toBe(true);
      expect(editButton().attributes('href')).toBe(
        `${release._links.editUrl}?${BACK_URL_PARAM}=${encodeURIComponent(window.location.href)}`,
      );
    });

    it('renders release name', () => {
      expect(wrapper.text()).toContain(release.name);
    });

    it('renders release description', () => {
      expect(wrapper.vm.$refs['gfm-content']).toBeDefined();
      expect($.fn.renderGFM).toHaveBeenCalledTimes(1);
    });

    it('renders release date', () => {
      expect(wrapper.text()).toContain(timeagoMixin.methods.timeFormatted(release.releasedAt));
    });

    it('renders number of assets provided', () => {
      expect(wrapper.find('.js-assets-count').text()).toContain(release.assets.count);
    });

    it('renders dropdown with the sources', () => {
      expect(wrapper.findAll('.js-sources-dropdown li').length).toEqual(
        release.assets.sources.length,
      );

      expect(wrapper.find('.js-sources-dropdown li a').attributes().href).toEqual(
        release.assets.sources[0].url,
      );

      expect(wrapper.find('.js-sources-dropdown li a').text()).toContain(
        release.assets.sources[0].format,
      );
    });

    it('renders list with the links provided', () => {
      expect(wrapper.findAll('.js-assets-list li').length).toEqual(release.assets.links.length);

      expect(wrapper.find('.js-assets-list li a').attributes().href).toEqual(
        release.assets.links[0].directAssetUrl,
      );

      expect(wrapper.find('.js-assets-list li a').text()).toContain(release.assets.links[0].name);
    });

    it('renders author avatar', () => {
      expect(wrapper.find('.user-avatar-link').exists()).toBe(true);
    });

    describe('external label', () => {
      it('renders external label when link is external', () => {
        expect(wrapper.find('.js-assets-list li a').text()).toContain('external source');
      });

      it('does not render external label when link is not external', () => {
        expect(wrapper.find('.js-assets-list li:nth-child(2) a').text()).not.toContain(
          'external source',
        );
      });
    });

    it('renders the footer', () => {
      expect(wrapper.find(ReleaseBlockFooter).exists()).toBe(true);
    });
  });

  it('renders commit sha', () => {
    release.commitPath = '/commit/example';

    return factory(release).then(() => {
      expect(wrapper.text()).toContain(release.commit.shortId);

      expect(wrapper.find('a[href="/commit/example"]').exists()).toBe(true);
    });
  });

  it('renders tag name', () => {
    release.tagPath = '/tag/example';

    return factory(release).then(() => {
      expect(wrapper.text()).toContain(release.tagName);

      expect(wrapper.find('a[href="/tag/example"]').exists()).toBe(true);
    });
  });

  it('does not render the milestone list if no milestones are associated to the release', () => {
    delete release.milestones;

    return factory(release).then(() => {
      expect(milestoneListLabel().exists()).toBe(false);
    });
  });

  it('renders upcoming release badge', () => {
    release.upcomingRelease = true;

    return factory(release).then(() => {
      expect(wrapper.text()).toContain('Upcoming Release');
    });
  });

  it('slugifies the tagName before setting it as the elements ID', () => {
    release.tagName = 'a dangerous tag name <script>alert("hello")</script>';

    return factory(release).then(() => {
      expect(wrapper.attributes().id).toBe('a-dangerous-tag-name-script-alert-hello-script');
    });
  });

  it('does not set the ID if tagName is missing', () => {
    release.tagName = undefined;

    return factory(release).then(() => {
      expect(wrapper.attributes().id).toBeUndefined();
    });
  });

  describe('evidence block', () => {
    it('renders the evidence block when the evidence is available and the feature flag is true', () =>
      factory(release, { releaseEvidenceCollection: true }).then(() =>
        expect(wrapper.find(EvidenceBlock).exists()).toBe(true),
      ));

    it('does not render the evidence block when the evidence is available but the feature flag is false', () =>
      factory(release, { releaseEvidenceCollection: true }).then(() =>
        expect(wrapper.find(EvidenceBlock).exists()).toBe(true),
      ));

    it('does not render the evidence block when there is no evidence', () => {
      release.evidenceSha = null;

      return factory(release).then(() => {
        expect(wrapper.find(EvidenceBlock).exists()).toBe(false);
      });
    });
  });

  describe('anchor scrolling', () => {
    let locationHash;

    beforeEach(() => {
      commonUtils.scrollToElement = jest.fn();
      urlUtility.getLocationHash = jest.fn().mockImplementation(() => locationHash);
    });

    const hasTargetBlueBackground = () => wrapper.classes('bg-line-target-blue');

    it('does not attempt to scroll the page if no anchor tag is included in the URL', () => {
      locationHash = '';
      return factory(release).then(() => {
        expect(commonUtils.scrollToElement).not.toHaveBeenCalled();
      });
    });

    it("does not attempt to scroll the page if the anchor tag doesn't match the release's tag name", () => {
      locationHash = 'v0.4';
      return factory(release).then(() => {
        expect(commonUtils.scrollToElement).not.toHaveBeenCalled();
      });
    });

    it("attempts to scroll itself into view if the anchor tag matches the release's tag name", () => {
      locationHash = release.tagName;
      return factory(release).then(() => {
        expect(commonUtils.scrollToElement).toHaveBeenCalledTimes(1);

        expect(commonUtils.scrollToElement).toHaveBeenCalledWith(wrapper.element);
      });
    });

    it('renders with a light blue background if it is the target of the anchor', () => {
      locationHash = release.tagName;

      return factory(release).then(() => {
        expect(hasTargetBlueBackground()).toBe(true);
      });
    });

    it('does not render with a light blue background if it is not the target of the anchor', () => {
      locationHash = '';

      return factory(release).then(() => {
        expect(hasTargetBlueBackground()).toBe(false);
      });
    });
  });

  describe('when the releaseIssueSummary feature flag is disabled', () => {
    describe('with default props', () => {
      beforeEach(() => factory(release, { releaseIssueSummary: false }));

      it('renders the milestone icon', () => {
        expect(
          milestoneListLabel()
            .find(Icon)
            .exists(),
        ).toBe(true);
      });

      it('renders the label as "Milestones" if more than one milestone is passed in', () => {
        expect(
          milestoneListLabel()
            .find('.js-label-text')
            .text(),
        ).toEqual('Milestones');
      });

      it('renders a link to the milestone with a tooltip', () => {
        const milestone = release.milestones[0];
        const milestoneLink = wrapper.find('.js-milestone-link');

        expect(milestoneLink.exists()).toBe(true);

        expect(milestoneLink.text()).toBe(milestone.title);

        expect(milestoneLink.attributes('href')).toBe(milestone.webUrl);

        expect(milestoneLink.attributes('title')).toBe(milestone.description);
      });
    });

    it('renders the label as "Milestone" if only a single milestone is passed in', () => {
      release.milestones = release.milestones.slice(0, 1);

      return factory(release, { releaseIssueSummary: false }).then(() => {
        expect(
          milestoneListLabel()
            .find('.js-label-text')
            .text(),
        ).toEqual('Milestone');
      });
    });
  });
});
