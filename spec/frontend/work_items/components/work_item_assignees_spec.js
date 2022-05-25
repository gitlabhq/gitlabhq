import { shallowMount } from '@vue/test-utils';
import { GlLink } from '@gitlab/ui';
import WorkItemAssignees from '~/work_items/components/work_item_assignees.vue';

const mockAssignees = [
  {
    __typename: 'UserCore',
    id: 'gid://gitlab/User/1',
    avatarUrl: '',
    webUrl: '',
    name: 'John Doe',
    username: 'doe_I',
  },
  {
    __typename: 'UserCore',
    id: 'gid://gitlab/User/2',
    avatarUrl: '',
    webUrl: '',
    name: 'Marcus Rutherford',
    username: 'ruthfull',
  },
];

describe('WorkItemAssignees component', () => {
  let wrapper;

  const findAssigneeLinks = () => wrapper.findAllComponents(GlLink);

  const createComponent = () => {
    wrapper = shallowMount(WorkItemAssignees, {
      propsData: {
        assignees: mockAssignees,
      },
    });
  };

  it('should pass the correct data-user-id attribute', () => {
    createComponent();

    expect(findAssigneeLinks().at(0).attributes('data-user-id')).toBe('1');
  });
});
