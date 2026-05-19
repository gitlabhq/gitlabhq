import { GlLink, GlIcon } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { cloneDeep } from 'lodash-es';
import { nextTick } from 'vue';
import originalOneReleaseQueryResponse from 'test_fixtures/graphql/releases/graphql/queries/one_release.query.graphql.json';
import { convertOneReleaseGraphQLResponse } from '~/releases/util';
import ReleaseBlockDetails from '~/releases/components/release_block_details.vue';

const originalRelease = convertOneReleaseGraphQLResponse(originalOneReleaseQueryResponse).data;

describe('Release block details', () => {
  let wrapper;
  let release;

  const factory = async (props = {}) => {
    wrapper = mount(ReleaseBlockDetails, {
      propsData: {
        author: originalRelease.author,
        commit: originalRelease.commit,
        commitPath: originalRelease.commitPath,
        tagName: originalRelease.tagName,
        tagPath: originalRelease.tagPath,
        previousReleaseSha: '',
        comparePath: '',
        releasedAt: originalRelease.releasedAt,
        createdAt: originalRelease.createdAt,
        sort: '',
        ...props,
      },
    });

    await nextTick();
  };

  beforeEach(() => {
    release = cloneDeep(originalRelease);
  });

  const commitInfoSection = () => wrapper.find('.js-commit-info');
  const commitInfoSectionLink = () => {
    const section = commitInfoSection();
    return section.exists() ? section.findComponent(GlLink) : null;
  };
  const tagInfoSection = () => wrapper.find('.js-tag-info');
  const tagInfoSectionLink = () => {
    const section = tagInfoSection();
    return section.exists() ? section.findComponent(GlLink) : null;
  };

  describe('with all release info', () => {
    beforeEach(() => factory());

    it('renders the author display name', () => {
      expect(wrapper.find('.user-avatar-link').text()).toBe(release.author.name);
    });

    it('renders the commit icon', () => {
      const commitIcon = commitInfoSection().findComponent(GlIcon);

      expect(commitIcon.exists()).toBe(true);
      expect(commitIcon.props('name')).toBe('commit');
    });

    it('renders the commit SHA with a link', () => {
      const commitLink = commitInfoSectionLink();

      expect(commitLink.exists()).toBe(true);
      expect(commitLink.text()).toBe(release.commit.shortId);
      expect(commitLink.attributes('href')).toBe(release.commitPath);
    });

    it('renders the tag icon', () => {
      const commitIcon = tagInfoSection().findComponent(GlIcon);

      expect(commitIcon.exists()).toBe(true);
      expect(commitIcon.props('name')).toBe('tag');
    });

    it('renders the tag name with a link', () => {
      const commitLink = tagInfoSection().findComponent(GlLink);

      expect(commitLink.exists()).toBe(true);
      expect(commitLink.text()).toBe(release.tagName);
      expect(commitLink.attributes('href')).toBe(release.tagPath);
    });
  });

  describe('without any commit info', () => {
    beforeEach(() => factory({ commit: undefined }));

    it('does not render any commit info', () => {
      expect(commitInfoSection().exists()).toBe(false);
    });
  });

  describe('without a commit URL', () => {
    beforeEach(() => factory({ commitPath: undefined }));

    it('renders the commit SHA as plain text (instead of a link)', () => {
      const link = commitInfoSectionLink();
      expect(link === null || !link.exists()).toBe(true);
      expect(commitInfoSection().text()).toContain(release.commit.shortId);
    });
  });

  describe('without a tag name', () => {
    beforeEach(() => factory({ tagName: undefined }));

    it('does not render any tag info', () => {
      expect(tagInfoSection().exists()).toBe(false);
    });
  });

  describe('without a tag URL', () => {
    beforeEach(() => factory({ tagPath: undefined }));

    it('renders the tag name as plain text (instead of a link)', () => {
      const link = tagInfoSectionLink();
      expect(link === null || !link.exists()).toBe(true);
      expect(tagInfoSection().text()).toBe(release.tagName);
    });
  });

  describe('with compare information', () => {
    const previousReleaseSha = 'abc1234567890def';
    const comparePath = '/project/path/-/compare/abc1234567890def...def1234567890abc';

    beforeEach(() =>
      factory({
        previousReleaseSha,
        comparePath,
      }),
    );

    it('renders the comparison icon', () => {
      const compareSection = wrapper.find('[data-testid="compare-info"]');
      expect(compareSection.exists()).toBe(true);

      const compareIcon = compareSection.findComponent(GlIcon);
      expect(compareIcon.exists()).toBe(true);
      expect(compareIcon.props('name')).toBe('comparison');
    });

    it('renders the compare link with short SHAs', () => {
      const compareSection = wrapper.find('[data-testid="compare-info"]');
      expect(compareSection.exists()).toBe(true);

      const compareLink = compareSection.findComponent(GlLink);
      expect(compareLink.exists()).toBe(true);
      expect(compareLink.attributes('href')).toBe(comparePath);
      expect(compareLink.text()).toBe(
        `${previousReleaseSha.slice(0, 7)}...${release.commit.shortId}`,
      );
    });
  });

  describe('without compare information', () => {
    beforeEach(() => factory({ previousReleaseSha: '', comparePath: '' }));

    it('does not render compare info', () => {
      expect(wrapper.find('[data-testid="compare-info"]').exists()).toBe(false);
    });
  });
});
