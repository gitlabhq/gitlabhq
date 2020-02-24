import $ from 'jquery';
import { mount } from '@vue/test-utils';
import { first } from 'underscore';
import EvidenceBlock from '~/releases/components/evidence_block.vue';
import ReleaseBlock from '~/releases/components/release_block.vue';
import ReleaseBlockFooter from '~/releases/components/release_block_footer.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { release as originalRelease } from '../mock_data';
import Icon from '~/vue_shared/components/icon.vue';
import { scrollToElement } from '~/lib/utils/common_utils';

const { convertObjectPropsToCamelCase } = jest.requireActual('~/lib/utils/common_utils');

let mockLocationHash;
jest.mock('~/lib/utils/url_utility', () => ({
  __esModule: true,
  getLocationHash: jest.fn().mockImplementation(() => mockLocationHash),
}));

jest.mock('~/lib/utils/common_utils', () => ({
  __esModule: true,
  scrollToElement: jest.fn(),
}));

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
    release = convertObjectPropsToCamelCase(originalRelease, { deep: true });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('with default props', () => {
    beforeEach(() => factory(release));

    it("renders the block with an id equal to the release's tag name", () => {
      expect(wrapper.attributes().id).toBe('v0.3');
    });

    it('renders an edit button that links to the "Edit release" page', () => {
      expect(editButton().exists()).toBe(true);
      expect(editButton().attributes('href')).toBe(release.Links.editUrl);
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
        first(release.assets.sources).url,
      );

      expect(wrapper.find('.js-sources-dropdown li a').text()).toContain(
        first(release.assets.sources).format,
      );
    });

    it('renders list with the links provided', () => {
      expect(wrapper.findAll('.js-assets-list li').length).toEqual(release.assets.links.length);

      expect(wrapper.find('.js-assets-list li a').attributes().href).toEqual(
        first(release.assets.links).url,
      );

      expect(wrapper.find('.js-assets-list li a').text()).toContain(
        first(release.assets.links).name,
      );
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

  it("does not render an edit button if release.Links.editUrl isn't a string", () => {
    delete release.Links;

    return factory(release).then(() => {
      expect(editButton().exists()).toBe(false);
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
    beforeEach(() => {
      scrollToElement.mockClear();
    });

    const hasTargetBlueBackground = () => wrapper.classes('bg-line-target-blue');

    it('does not attempt to scroll the page if no anchor tag is included in the URL', () => {
      mockLocationHash = '';
      return factory(release).then(() => {
        expect(scrollToElement).not.toHaveBeenCalled();
      });
    });

    it("does not attempt to scroll the page if the anchor tag doesn't match the release's tag name", () => {
      mockLocationHash = 'v0.4';
      return factory(release).then(() => {
        expect(scrollToElement).not.toHaveBeenCalled();
      });
    });

    it("attempts to scroll itself into view if the anchor tag matches the release's tag name", () => {
      mockLocationHash = release.tagName;
      return factory(release).then(() => {
        expect(scrollToElement).toHaveBeenCalledTimes(1);

        expect(scrollToElement).toHaveBeenCalledWith(wrapper.element);
      });
    });

    it('renders with a light blue background if it is the target of the anchor', () => {
      mockLocationHash = release.tagName;

      return factory(release).then(() => {
        expect(hasTargetBlueBackground()).toBe(true);
      });
    });

    it('does not render with a light blue background if it is not the target of the anchor', () => {
      mockLocationHash = '';

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
        const milestone = first(release.milestones);
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
