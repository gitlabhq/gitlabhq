import { shallowMount } from '@vue/test-utils';
import { mockAssigneesList } from 'jest/boards/mock_data';
import IssueAssignees from '~/issuable/components/issue_assignees.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';

const TEST_CSS_CLASSES = 'test-classes';
const TEST_MAX_VISIBLE = 4;
const TEST_ICON_SIZE = 16;

describe('IssueAssigneesComponent', () => {
  let wrapper;
  let vm;

  const factory = (props) => {
    wrapper = shallowMount(IssueAssignees, {
      propsData: {
        assignees: mockAssigneesList,
        ...props,
      },
    });
    vm = wrapper.vm;
  };

  const findTooltipText = () => wrapper.find('.js-assignee-tooltip').text();
  const findAvatars = () => wrapper.findAllComponents(UserAvatarLink);
  const findOverflowCounter = () => wrapper.find('.avatar-counter');

  it('returns default data props', () => {
    factory({ assignees: mockAssigneesList });
    expect(vm.iconSize).toBe(24);
    expect(vm.maxVisible).toBe(3);
    expect(vm.maxAssignees).toBe(99);
  });

  describe.each`
    numAssignees | maxVisible | expectedShown | expectedHidden
    ${0}         | ${3}       | ${0}          | ${''}
    ${1}         | ${3}       | ${1}          | ${''}
    ${2}         | ${3}       | ${2}          | ${''}
    ${3}         | ${3}       | ${3}          | ${''}
    ${4}         | ${3}       | ${2}          | ${'+2'}
    ${5}         | ${2}       | ${1}          | ${'+4'}
    ${1000}      | ${5}       | ${4}          | ${'99+'}
  `(
    'with assignees ($numAssignees) and maxVisible ($maxVisible)',
    ({ numAssignees, maxVisible, expectedShown, expectedHidden }) => {
      beforeEach(() => {
        factory({ assignees: Array(numAssignees).fill({}), maxVisible });
      });

      if (expectedShown) {
        it('shows assignee avatars', () => {
          expect(findAvatars().length).toEqual(expectedShown);
        });
      } else {
        it('does not show assignee avatars', () => {
          expect(findAvatars().length).toEqual(0);
        });
      }

      if (expectedHidden) {
        it('shows overflow counter', () => {
          const hiddenCount = numAssignees - expectedShown;

          expect(findOverflowCounter().exists()).toBe(true);
          expect(findOverflowCounter().text()).toEqual(expectedHidden.toString());
          expect(findOverflowCounter().attributes('title')).toEqual(
            `${hiddenCount} more assignees`,
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

    it('computes alt text for assignee avatar', () => {
      expect(vm.avatarUrlTitle(mockAssigneesList[0])).toBe('Assigned to Terrell Graham');
    });

    it('renders assignee', () => {
      const data = findAvatars().wrappers.map((x) => ({
        ...x.props(),
      }));

      const expected = mockAssigneesList.slice(0, TEST_MAX_VISIBLE - 1).map((x) =>
        expect.objectContaining({
          imgAlt: `Assigned to ${x.name}`,
          imgCssClasses: TEST_CSS_CLASSES,
          imgSrc: x.avatar_url,
          imgSize: TEST_ICON_SIZE,
        }),
      );

      expect(data).toEqual(expected);
    });

    describe('assignee tooltips', () => {
      it('renders "Assignee" header', () => {
        expect(findTooltipText()).toContain('Assignee');
      });

      it('renders assignee name', () => {
        expect(findTooltipText()).toContain('Terrell Graham');
      });

      it('renders assignee @username', () => {
        expect(findTooltipText()).toContain('@monserrate.gleichner');
      });

      it('does not render `@` when username not available', () => {
        const userName = 'User without username';
        factory({
          assignees: [
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
      it('properly sets href on each assignee', () => {
        const template = findAvatars().wrappers.map((x) => x.props('linkHref'));
        const expected = mockAssigneesList
          .slice(0, TEST_MAX_VISIBLE - 1)
          .map((x) => `/${x.username}`);

        expect(template).toEqual(expected);
      });
    });
  });
});
