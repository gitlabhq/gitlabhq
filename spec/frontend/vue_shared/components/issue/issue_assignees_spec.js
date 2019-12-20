import { shallowMount } from '@vue/test-utils';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import IssueAssignees from '~/vue_shared/components/issue/issue_assignees.vue';
import { mockAssigneesList } from '../../../../javascripts/boards/mock_data';

const TEST_CSS_CLASSES = 'test-classes';
const TEST_MAX_VISIBLE = 4;
const TEST_ICON_SIZE = 16;

describe('IssueAssigneesComponent', () => {
  let wrapper;
  let vm;

  const factory = props => {
    wrapper = shallowMount(IssueAssignees, {
      propsData: {
        assignees: mockAssigneesList,
        ...props,
      },
      sync: false,
      attachToDocument: true,
    });
    vm = wrapper.vm; // eslint-disable-line
  };

  const findTooltipText = () => wrapper.find('.js-assignee-tooltip').text();
  const findAvatars = () => wrapper.findAll(UserAvatarLink);
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
          expect(findOverflowCounter().attributes('data-original-title')).toEqual(
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
      expect(vm.avatarUrlTitle(mockAssigneesList[0])).toBe('Avatar for Terrell Graham');
    });

    it('renders component root element with class `issue-assignees`', () => {
      expect(wrapper.element.classList.contains('issue-assignees')).toBe(true);
    });

    it('renders assignee', () => {
      const data = findAvatars().wrappers.map(x => ({
        ...x.props(),
      }));

      const expected = mockAssigneesList.slice(0, TEST_MAX_VISIBLE - 1).map(x =>
        expect.objectContaining({
          linkHref: x.web_url,
          imgAlt: `Avatar for ${x.name}`,
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
    });
  });
});
