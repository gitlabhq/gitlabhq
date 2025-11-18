import { GlBadge, GlTruncate } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CommitListItemBadges from '~/projects/commits/components/commit_list_item_badges.vue';
import SignatureBadge from '~/commit/components/signature_badge.vue';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import { mockCommit } from './mock_data';

describe('CommitListItemBadges', () => {
  let wrapper;
  let narrowScreenContainer;
  let wideScreenContainer;

  const createComponent = (commit = mockCommit) => {
    wrapper = shallowMountExtended(CommitListItemBadges, {
      propsData: {
        commit,
      },
    });
  };

  const findCommitId = () => wrapper.findByTestId('commit-sha');

  beforeEach(() => {
    createComponent();

    narrowScreenContainer = wrapper.findByTestId('commit-badges-mobile-container');
    wideScreenContainer = wrapper.findByTestId('commit-badges-container');
  });

  it('renders both narrow and wide screen containers', () => {
    expect(narrowScreenContainer.classes()).toEqual(
      expect.arrayContaining(['gl-flex', 'gl-items-center', 'gl-gap-3', '@md/panel:gl-hidden']),
    );
    expect(wideScreenContainer.classes()).toEqual(
      expect.arrayContaining(['gl-hidden', 'gl-items-center', 'gl-gap-3', '@md/panel:gl-flex']),
    );
  });

  describe('commit ID', () => {
    it('renders commit short ID only in mobile container', () => {
      const commitId = findCommitId();
      expect(commitId.text()).toBe(mockCommit.shortId);

      expect(narrowScreenContainer.find('[data-testid="commit-sha"]').exists()).toBe(true);
      expect(wideScreenContainer.find('[data-testid="commit-sha"]').exists()).toBe(false);
    });
  });

  describe('tag badge', () => {
    it('renders tag badge in both containers', () => {
      const tagBadges = wrapper.findAllComponents(GlBadge);
      expect(tagBadges).toHaveLength(2);

      tagBadges.wrappers.forEach((badge) => {
        expect(badge.props()).toMatchObject({
          icon: 'tag',
          variant: 'neutral',
        });
      });
    });

    it('renders truncated text with tooltip enabled', () => {
      const truncate = wrapper.findComponent(GlTruncate);

      expect(truncate.props()).toMatchObject({
        withTooltip: true,
        text: 'V1.2.3',
      });
    });
  });

  describe('signature badge', () => {
    it('renders signature badge in both containers', () => {
      const signatureBadges = wrapper.findAllComponents(SignatureBadge);
      expect(signatureBadges).toHaveLength(2);

      signatureBadges.wrappers.forEach((badge) => {
        expect(badge.props('signature')).toBe(mockCommit.signature);
      });
    });
  });

  describe('CI status icon', () => {
    it('renders CI icon in both containers', () => {
      const ciIcons = wrapper.findAllComponents(CiIcon);
      expect(ciIcons).toHaveLength(2);

      ciIcons.wrappers.forEach((icon) => {
        expect(icon.props('status')).toBe(mockCommit.pipelines.edges[0].node.detailedStatus);
      });
    });
  });
});
