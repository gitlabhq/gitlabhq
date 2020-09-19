import { shallowMount } from '@vue/test-utils';
import IssuableAssignees from '~/sidebar/components/assignees/issuable_assignees.vue';
import UncollapsedAssigneeList from '~/sidebar/components/assignees/uncollapsed_assignee_list.vue';

describe('IssuableAssignees', () => {
  let wrapper;

  const createComponent = (props = { users: [] }) => {
    wrapper = shallowMount(IssuableAssignees, {
      provide: {
        rootPath: '',
      },
      propsData: { ...props },
    });
  };
  const findLabel = () => wrapper.find('[data-testid="assigneeLabel"');
  const findUncollapsedAssigneeList = () => wrapper.find(UncollapsedAssigneeList);
  const findEmptyAssignee = () => wrapper.find('[data-testid="none"]');

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when no assignees are present', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders "None"', () => {
      expect(findEmptyAssignee().text()).toBe('None');
    });

    it('renders "0 assignees"', () => {
      expect(findLabel().text()).toBe('0 Assignees');
    });
  });

  describe('when assignees are present', () => {
    it('renders UncollapsedAssigneesList', () => {
      createComponent({ users: [{ id: 1 }] });

      expect(findUncollapsedAssigneeList().exists()).toBe(true);
    });

    it.each`
      assignees                 | expected
      ${[{ id: 1 }]}            | ${'Assignee'}
      ${[{ id: 1 }, { id: 2 }]} | ${'2 Assignees'}
    `(
      'when assignees have a length of $assignees.length, it renders $expected',
      ({ assignees, expected }) => {
        createComponent({ users: assignees });

        expect(findLabel().text()).toBe(expected);
      },
    );
  });
});
