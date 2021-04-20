import { shallowMount } from '@vue/test-utils';
import IssuableAssignees from '~/sidebar/components/assignees/issuable_assignees.vue';
import UncollapsedAssigneeList from '~/sidebar/components/assignees/uncollapsed_assignee_list.vue';

describe('IssuableAssignees', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(IssuableAssignees, {
      provide: {
        rootPath: '',
      },
      propsData: {
        users: [],
        ...props,
      },
    });
  };
  const findUncollapsedAssigneeList = () => wrapper.find(UncollapsedAssigneeList);
  const findEmptyAssignee = () => wrapper.find('[data-testid="none"]');

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when no assignees are present', () => {
    it('renders "None - assign yourself" when user is logged in', () => {
      createComponent({ signedIn: true });
      expect(findEmptyAssignee().text()).toBe('None - assign yourself');
    });

    it('renders "None" when user is not logged in', () => {
      createComponent();
      expect(findEmptyAssignee().text()).toBe('None');
    });
  });

  describe('when assignees are present', () => {
    it('renders UncollapsedAssigneesList', () => {
      createComponent({ users: [{ id: 1 }] });

      expect(findUncollapsedAssigneeList().exists()).toBe(true);
    });
  });

  describe('when clicking "assign yourself"', () => {
    it('emits "assign-self"', () => {
      createComponent({ signedIn: true });
      wrapper.find('[data-testid="assign-yourself"]').vm.$emit('click');
      expect(wrapper.emitted('assign-self')).toHaveLength(1);
    });
  });
});
