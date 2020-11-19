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
  });

  describe('when assignees are present', () => {
    it('renders UncollapsedAssigneesList', () => {
      createComponent({ users: [{ id: 1 }] });

      expect(findUncollapsedAssigneeList().exists()).toBe(true);
    });
  });
});
