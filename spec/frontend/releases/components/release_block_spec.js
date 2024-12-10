import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import originalOneReleaseQueryResponse from 'test_fixtures/graphql/releases/graphql/queries/one_release.query.graphql.json';
import { convertOneReleaseGraphQLResponse } from '~/releases/util';
import * as commonUtils from '~/lib/utils/common_utils';
import * as urlUtility from '~/lib/utils/url_utility';
import EvidenceBlock from '~/releases/components/evidence_block.vue';
import ReleaseBlockDeployments from '~/releases/components/release_block_deployments.vue';
import ReleaseBlock from '~/releases/components/release_block.vue';
import ReleaseBlockFooter from '~/releases/components/release_block_footer.vue';
import { BACK_URL_PARAM } from '~/releases/constants';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import { mockDeployment } from '../mock_data';

jest.mock('~/behaviors/markdown/render_gfm');

describe('Release block', () => {
  let wrapper;
  let release;
  let deployments = [mockDeployment];

  const factory = async (releaseProp, featureFlags = {}) => {
    wrapper = mount(ReleaseBlock, {
      propsData: {
        release: releaseProp,
        deployments,
      },
      provide: {
        projectPath: 'project/path',
        glFeatures: {
          ...featureFlags,
        },
      },
    });

    await nextTick();
  };

  const milestoneListLabel = () => wrapper.find('.js-milestone-list-label');
  const editButton = () => wrapper.find('.js-edit-button');

  beforeEach(() => {
    release = convertOneReleaseGraphQLResponse(originalOneReleaseQueryResponse).data;
  });

  describe('with default props', () => {
    beforeEach(() => factory(release));

    it("renders the block with an id equal to the release's tag name", () => {
      expect(wrapper.attributes().id).toBe(release.tagName);
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
      expect(renderGFM).toHaveBeenCalledTimes(1);
    });

    it('renders release date', () => {
      expect(wrapper.text()).toContain(timeagoMixin.methods.timeFormatted(release.releasedAt));
    });

    it('renders author avatar', () => {
      expect(wrapper.find('.user-avatar-link').exists()).toBe(true);
    });

    it('renders the footer', () => {
      expect(wrapper.findComponent(ReleaseBlockFooter).exists()).toBe(true);
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

  describe('release block deployments', () => {
    it('renders the release block deployments when the deployments list is not empty', async () => {
      await factory(release);

      expect(wrapper.findComponent(ReleaseBlockDeployments).exists()).toBe(true);
    });

    it('does not render the release block deployments when the deployments list is empty', async () => {
      deployments = [];

      await factory(release);

      expect(wrapper.findComponent(ReleaseBlockDeployments).exists()).toBe(false);
    });
  });

  describe('evidence block', () => {
    it('renders the evidence block when the evidence is available', () => {
      return factory(release).then(() => {
        expect(wrapper.findComponent(EvidenceBlock).exists()).toBe(true);
      });
    });

    it('does not render the evidence block when there is no evidence', () => {
      release.evidences = [];

      return factory(release).then(() => {
        expect(wrapper.findComponent(EvidenceBlock).exists()).toBe(false);
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

  describe('with no edit link provided', () => {
    beforeEach(() => factory({ ...release, _links: { editUrl: null } }));

    it('does not show an edit button', () => {
      expect(editButton().exists()).toBe(false);
    });
  });
});
