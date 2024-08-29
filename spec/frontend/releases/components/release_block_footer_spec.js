import { GlLink, GlIcon } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { cloneDeep } from 'lodash';
import { nextTick } from 'vue';
import originalOneReleaseQueryResponse from 'test_fixtures/graphql/releases/graphql/queries/one_release.query.graphql.json';
import { convertOneReleaseGraphQLResponse } from '~/releases/util';
import { RELEASED_AT_ASC, RELEASED_AT_DESC, CREATED_ASC, CREATED_DESC } from '~/releases/constants';
import { trimText } from 'helpers/text_helper';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import ReleaseBlockFooter from '~/releases/components/release_block_footer.vue';

// TODO: Encapsulate date helpers https://gitlab.com/gitlab-org/gitlab/-/issues/320883
const MONTHS_IN_MS = 1000 * 60 * 60 * 24 * 31;
const mockFutureDate = new Date(new Date().getTime() + MONTHS_IN_MS);

const originalRelease = convertOneReleaseGraphQLResponse(originalOneReleaseQueryResponse).data;

describe('Release block footer', () => {
  let wrapper;
  let release;

  const factory = async (props = {}) => {
    wrapper = mount(ReleaseBlockFooter, {
      propsData: {
        ...originalRelease,
        ...props,
      },
    });

    await nextTick();
  };

  beforeEach(() => {
    release = cloneDeep(originalRelease);
  });

  const commitInfoSection = () => wrapper.find('.js-commit-info');
  const commitInfoSectionLink = () => commitInfoSection().findComponent(GlLink);
  const tagInfoSection = () => wrapper.find('.js-tag-info');
  const tagInfoSectionLink = () => tagInfoSection().findComponent(GlLink);
  const authorDateInfoSection = () => wrapper.find('.js-author-date-info');
  const findUserAvatar = () => wrapper.findComponent(UserAvatarLink);

  describe.each`
    sortFlag            | expectedInfoString
    ${null}             | ${'Created'}
    ${CREATED_ASC}      | ${'Created'}
    ${CREATED_DESC}     | ${'Created'}
    ${RELEASED_AT_ASC}  | ${'Released'}
    ${RELEASED_AT_DESC} | ${'Released'}
  `('with sorting set to $sortFlag', ({ sortFlag, expectedInfoString }) => {
    const dateAt =
      expectedInfoString === 'Created' ? originalRelease.createdAt : originalRelease.releasedAt;

    describe.each`
      dateType           | dateFlag          | expectedInfoStringPrefix | expectedDateString
      ${'empty'}         | ${undefined}      | ${null}                  | ${null}
      ${'in the past'}   | ${dateAt}         | ${null}                  | ${'1 year ago'}
      ${'in the future'} | ${mockFutureDate} | ${'Will be'}             | ${'in 1 month'}
    `(
      'with date set to $dateType',
      ({ dateFlag, expectedInfoStringPrefix, expectedDateString }) => {
        describe.each`
          authorType   | authorFlag                | expectedAuthorString
          ${'empty'}   | ${undefined}              | ${null}
          ${'present'} | ${originalRelease.author} | ${'by user1'}
        `('with author set to $authorType', ({ authorFlag, expectedAuthorString }) => {
          const propsData = { sort: sortFlag, author: authorFlag };
          if (dateFlag !== '') {
            propsData.createdAt = dateFlag;
            propsData.releasedAt = dateFlag;
          }

          beforeEach(() => {
            factory({ ...propsData });
          });

          const expectedString = [
            expectedInfoStringPrefix,
            expectedInfoStringPrefix ? expectedInfoString.toLowerCase() : expectedInfoString,
            expectedDateString,
            expectedAuthorString,
          ];

          if (authorFlag || dateFlag) {
            it('renders the author and creation time info', () => {
              expect(trimText(authorDateInfoSection().text())).toBe(
                expectedString.filter((n) => n).join(' '),
              );
            });
            if (authorFlag) {
              it("renders the author's avatar image", () => {
                const avatarImg = findUserAvatar();

                expect(avatarImg.exists()).toBe(true);
                expect(avatarImg.props('imgSrc')).toBe(release.author.avatarUrl);
              });

              it("renders a link to the author's profile", () => {
                const authorLink = authorDateInfoSection().findComponent(GlLink);

                expect(authorLink.exists()).toBe(true);
                expect(authorLink.attributes('href')).toBe(release.author.webUrl);
              });
            } else {
              it("does not render the author's avatar image", () => {
                const avatarImg = authorDateInfoSection().find('img');

                expect(avatarImg.exists()).toBe(false);
              });

              it("does not render a link to the author's profile", () => {
                const authorLink = authorDateInfoSection().findComponent(GlLink);

                expect(authorLink.exists()).toBe(false);
              });
            }
          } else {
            it('does not render the author and creation time info', () => {
              expect(authorDateInfoSection().exists()).toBe(false);
            });
          }

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
      },
    );
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
      expect(commitInfoSection().text()).toBe(release.commit.shortId);
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
      expect(tagInfoSection().text()).toBe(release.tagName);
    });
  });
});
