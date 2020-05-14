import { mount } from '@vue/test-utils';
import { GlLink } from '@gitlab/ui';
import { trimText } from 'helpers/text_helper';
import ReleaseBlockFooter from '~/releases/components/release_block_footer.vue';
import Icon from '~/vue_shared/components/icon.vue';
import { release as originalRelease } from '../mock_data';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { cloneDeep } from 'lodash';

const mockFutureDate = new Date(9999, 0, 0).toISOString();
let mockIsFutureRelease = false;

jest.mock('~/vue_shared/mixins/timeago', () => ({
  methods: {
    timeFormatted() {
      return mockIsFutureRelease ? 'in 1 month' : '7 fortnights ago';
    },
    tooltipTitle() {
      return 'February 30, 2401';
    },
  },
}));

describe('Release block footer', () => {
  let wrapper;
  let release;

  const factory = (props = {}) => {
    wrapper = mount(ReleaseBlockFooter, {
      propsData: {
        ...convertObjectPropsToCamelCase(release, { deep: true }),
        ...props,
      },
    });

    return wrapper.vm.$nextTick();
  };

  beforeEach(() => {
    release = cloneDeep(originalRelease);
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    mockIsFutureRelease = false;
  });

  const commitInfoSection = () => wrapper.find('.js-commit-info');
  const commitInfoSectionLink = () => commitInfoSection().find(GlLink);
  const tagInfoSection = () => wrapper.find('.js-tag-info');
  const tagInfoSectionLink = () => tagInfoSection().find(GlLink);
  const authorDateInfoSection = () => wrapper.find('.js-author-date-info');

  describe('with all props provided', () => {
    beforeEach(() => factory());

    it('renders the commit icon', () => {
      const commitIcon = commitInfoSection().find(Icon);

      expect(commitIcon.exists()).toBe(true);
      expect(commitIcon.props('name')).toBe('commit');
    });

    it('renders the commit SHA with a link', () => {
      const commitLink = commitInfoSectionLink();

      expect(commitLink.exists()).toBe(true);
      expect(commitLink.text()).toBe(release.commit.short_id);
      expect(commitLink.attributes('href')).toBe(release.commit_path);
    });

    it('renders the tag icon', () => {
      const commitIcon = tagInfoSection().find(Icon);

      expect(commitIcon.exists()).toBe(true);
      expect(commitIcon.props('name')).toBe('tag');
    });

    it('renders the tag name with a link', () => {
      const commitLink = tagInfoSection().find(GlLink);

      expect(commitLink.exists()).toBe(true);
      expect(commitLink.text()).toBe(release.tag_name);
      expect(commitLink.attributes('href')).toBe(release.tag_path);
    });

    it('renders the author and creation time info', () => {
      expect(trimText(authorDateInfoSection().text())).toBe(
        `Created 7 fortnights ago by ${release.author.username}`,
      );
    });

    describe('when the release date is in the past', () => {
      it('prefixes the creation info with "Created"', () => {
        expect(trimText(authorDateInfoSection().text())).toEqual(expect.stringMatching(/^Created/));
      });
    });

    describe('renders the author and creation time info with future release date', () => {
      beforeEach(() => {
        mockIsFutureRelease = true;
        factory({ releasedAt: mockFutureDate });
      });

      it('renders the release date without the author name', () => {
        expect(trimText(authorDateInfoSection().text())).toBe(
          `Will be created in 1 month by ${release.author.username}`,
        );
      });
    });

    describe('when the release date is in the future', () => {
      beforeEach(() => {
        mockIsFutureRelease = true;
        factory({ releasedAt: mockFutureDate });
      });

      it('prefixes the creation info with "Will be created"', () => {
        expect(trimText(authorDateInfoSection().text())).toEqual(
          expect.stringMatching(/^Will be created/),
        );
      });
    });

    it("renders the author's avatar image", () => {
      const avatarImg = authorDateInfoSection().find('img');

      expect(avatarImg.exists()).toBe(true);
      expect(avatarImg.attributes('src')).toBe(release.author.avatar_url);
    });

    it("renders a link to the author's profile", () => {
      const authorLink = authorDateInfoSection().find(GlLink);

      expect(authorLink.exists()).toBe(true);
      expect(authorLink.attributes('href')).toBe(release.author.web_url);
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
      expect(commitInfoSectionLink().exists()).toBe(false);
      expect(commitInfoSection().text()).toBe(release.commit.short_id);
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
      expect(tagInfoSectionLink().exists()).toBe(false);
      expect(tagInfoSection().text()).toBe(release.tag_name);
    });
  });

  describe('without any author info', () => {
    beforeEach(() => factory({ author: undefined }));

    it('renders the release date without the author name', () => {
      expect(trimText(authorDateInfoSection().text())).toBe(`Created 7 fortnights ago`);
    });
  });

  describe('future release without any author info', () => {
    beforeEach(() => {
      mockIsFutureRelease = true;
      factory({ author: undefined, releasedAt: mockFutureDate });
    });

    it('renders the release date without the author name', () => {
      expect(trimText(authorDateInfoSection().text())).toBe(`Will be created in 1 month`);
    });
  });

  describe('without a released at date', () => {
    beforeEach(() => factory({ releasedAt: undefined }));

    it('renders the author name without the release date', () => {
      expect(trimText(authorDateInfoSection().text())).toBe(
        `Created by ${release.author.username}`,
      );
    });
  });

  describe('without a release date or author info', () => {
    beforeEach(() => factory({ author: undefined, releasedAt: undefined }));

    it('does not render any author or release date info', () => {
      expect(authorDateInfoSection().exists()).toBe(false);
    });
  });
});
