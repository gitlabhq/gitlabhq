import { GlLink, GlTokenSelector } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemAssignees from '~/work_items/components/work_item_assignees.vue';
import localUpdateWorkItemMutation from '~/work_items/graphql/local_update_work_item.mutation.graphql';

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

const workItemId = 'gid://gitlab/WorkItem/1';

const mutate = jest.fn();

describe('WorkItemAssignees component', () => {
  let wrapper;

  const findAssigneeLinks = () => wrapper.findAllComponents(GlLink);
  const findTokenSelector = () => wrapper.findComponent(GlTokenSelector);

  const findEmptyState = () => wrapper.findByTestId('empty-state');

  const createComponent = ({ assignees = mockAssignees } = {}) => {
    wrapper = mountExtended(WorkItemAssignees, {
      propsData: {
        assignees,
        workItemId,
      },
      mocks: {
        $apollo: {
          mutate,
        },
      },
      attachTo: document.body,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('should pass the correct data-user-id attribute', () => {
    createComponent();

    expect(findAssigneeLinks().at(0).attributes('data-user-id')).toBe('1');
  });

  describe('when there are assignees', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should focus token selector on token removal', async () => {
      findTokenSelector().vm.$emit('token-remove', mockAssignees[0].id);
      await nextTick();

      expect(findEmptyState().exists()).toBe(false);
      expect(findTokenSelector().element.contains(document.activeElement)).toBe(true);
    });

    it('should call a mutation on clicking outside the token selector', async () => {
      findTokenSelector().vm.$emit('input', [mockAssignees[0]]);
      findTokenSelector().vm.$emit('token-remove');
      await nextTick();
      expect(mutate).not.toHaveBeenCalled();

      findTokenSelector().vm.$emit('blur', new FocusEvent({ relatedTarget: null }));
      await nextTick();

      expect(mutate).toHaveBeenCalledWith({
        mutation: localUpdateWorkItemMutation,
        variables: {
          input: { id: workItemId, assigneeIds: [mockAssignees[0].id] },
        },
      });
    });
  });
});
