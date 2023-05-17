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
        editable: true,
        ...props,
      },
    });
  };
  const findUncollapsedAssigneeList = () => wrapper.findComponent(UncollapsedAssigneeList);
  const findEmptyAssignee = () => wrapper.find('[data-testid="none"]');

  describe('when no assignees are present', () => {
    it.each`
      signedIn | editable | message
      ${true}  | ${true}  | ${'None - assign yourself'}
      ${true}  | ${false} | ${'None'}
      ${false} | ${true}  | ${'None'}
      ${false} | ${false} | ${'None'}
    `(
      'renders "$message" when signedIn is $signedIn and editable is $editable',
      ({ signedIn, editable, message }) => {
        createComponent({ signedIn, editable });
        expect(findEmptyAssignee().text()).toBe(message);
      },
    );
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
