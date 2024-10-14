import { shallowMount } from '@vue/test-utils';
import { mockAssigneesList as mockReviewersList } from 'jest/boards/mock_data';
import MergeRequestReviewers from '~/issuable/components/merge_request_reviewers.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';

const TEST_CSS_CLASSES = 'test-classes';
const TEST_MAX_VISIBLE = 4;
const TEST_ICON_SIZE = 16;

function normalizeMockReviewers(data) {
  return data.map((reviewer) => {
    const normalizedReviewer = { ...reviewer };

    normalizedReviewer.avatarUrl = reviewer.avatar_url;
    delete normalizedReviewer.avatar_url;

    return normalizedReviewer;
  });
}

describe('MergeRequestReviewersComponent', () => {
  let wrapper;
  let vm;

  const factory = (props) => {
    wrapper = shallowMount(MergeRequestReviewers, {
      propsData: {
        reviewers: normalizeMockReviewers(mockReviewersList),
        ...props,
      },
    });
    vm = wrapper.vm;
  };

  const findTooltipText = () => wrapper.find('[data-testid=js-reviewer-tooltip]').text();
  const findAvatars = () => wrapper.findAllComponents(UserAvatarLink);
  const findOverflowCounter = () => wrapper.find('.avatar-counter');

  it('returns default data props', () => {
    factory({ reviewers: mockReviewersList });
    expect(vm.iconSize).toBe(24);
    expect(vm.maxVisible).toBe(3);
    expect(vm.maxReviewers).toBe(99);
  });

  describe.each`
    numReviewers | maxVisible | expectedShown | expectedHidden
    ${0}         | ${3}       | ${0}          | ${''}
    ${1}         | ${3}       | ${1}          | ${''}
    ${2}         | ${3}       | ${2}          | ${''}
    ${3}         | ${3}       | ${3}          | ${''}
    ${4}         | ${3}       | ${2}          | ${'+2'}
    ${5}         | ${2}       | ${1}          | ${'+4'}
    ${1000}      | ${5}       | ${4}          | ${'99+'}
  `(
    'with reviewers ($numReviewers) and maxVisible ($maxVisible)',
    ({ numReviewers, maxVisible, expectedShown, expectedHidden }) => {
      beforeEach(() => {
        factory({ reviewers: Array(numReviewers).fill({}), maxVisible });
      });

      if (expectedShown) {
        it('shows reviewer avatars', () => {
          expect(findAvatars().length).toEqual(expectedShown);
        });
      } else {
        it('does not show reviewer avatars', () => {
          expect(findAvatars().length).toEqual(0);
        });
      }

      if (expectedHidden) {
        it('shows overflow counter', () => {
          const hiddenCount = numReviewers - expectedShown;

          expect(findOverflowCounter().exists()).toBe(true);
          expect(findOverflowCounter().text()).toEqual(expectedHidden.toString());
          expect(findOverflowCounter().attributes('title')).toEqual(
            `${hiddenCount} more reviewers`,
          );
        });
      } else {
        it('does not show overflow counter', () => {
          expect(findOverflowCounter().exists()).toBe(false);
        });
      }
    },
  );

  describe('when mounted', () => {
    beforeEach(() => {
      factory({
        imgCssClasses: TEST_CSS_CLASSES,
        maxVisible: TEST_MAX_VISIBLE,
        iconSize: TEST_ICON_SIZE,
      });
    });

    it('computes alt text for reviewer avatar', () => {
      expect(vm.avatarUrlTitle(mockReviewersList[0])).toBe('Review requested from Terrell Graham');
    });

    it('renders reviewer', () => {
      const data = findAvatars().wrappers.map((x) => ({
        ...x.props(),
      }));

      const expected = mockReviewersList.slice(0, TEST_MAX_VISIBLE - 1).map((x) =>
        expect.objectContaining({
          imgAlt: `Review requested from ${x.name}`,
          imgCssClasses: TEST_CSS_CLASSES,
          imgSrc: x.avatar_url,
          imgSize: TEST_ICON_SIZE,
        }),
      );

      expect(data).toEqual(expected);
    });

    describe('reviewer tooltips', () => {
      it('renders "Reviewer" header', () => {
        expect(findTooltipText()).toContain('Reviewer');
      });

      it('renders reviewer name', () => {
        expect(findTooltipText()).toContain('Terrell Graham');
      });

      it('renders reviewer @username', () => {
        expect(findTooltipText()).toContain('@monserrate.gleichner');
      });

      it('does not render `@` when username not available', () => {
        const userName = 'User without username';
        factory({
          reviewers: [
            {
              name: userName,
            },
          ],
        });

        const tooltipText = findTooltipText();

        expect(tooltipText).toContain(userName);
        expect(tooltipText).not.toContain('@');
      });
    });
    describe('Author Link', () => {
      it('properly sets href on each reviewer', () => {
        const template = findAvatars().wrappers.map((x) => x.props('linkHref'));
        const expected = mockReviewersList
          .slice(0, TEST_MAX_VISIBLE - 1)
          .map((x) => `/${x.username}`);

        expect(template).toEqual(expected);
      });
    });
  });
});
