import { GlDisclosureDropdown } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { TYPE_EPIC, TYPE_INCIDENT, TYPE_ISSUE } from '~/issues/constants';
import TaskListItemActions from '~/issues/show/components/task_list_item_actions.vue';
import eventHub from '~/issues/show/event_hub';

jest.mock('~/issues/show/event_hub');

describe('TaskListItemActions component', () => {
  let wrapper;

  const findGlDisclosureDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findConvertToTaskItem = () => wrapper.findByTestId('convert');
  const findDeleteItem = () => wrapper.findByTestId('delete');

  const mountComponent = ({ issuableType = TYPE_ISSUE } = {}) => {
    const li = document.createElement('li');
    li.dataset.sourcepos = '3:1-3:10';
    li.appendChild(document.createElement('div'));
    document.body.appendChild(li);

    wrapper = shallowMountExtended(TaskListItemActions, {
      provide: { canUpdate: true, issuableType },
      attachTo: document.querySelector('div'),
    });
  };

  it('renders dropdown', () => {
    mountComponent();

    expect(findGlDisclosureDropdown().props()).toMatchObject({
      category: 'tertiary',
      icon: 'ellipsis_v',
      placement: 'right',
      toggleText: TaskListItemActions.i18n.taskActions,
      textSrOnly: true,
    });
  });

  describe('"Convert to task" dropdown item', () => {
    describe.each`
      issuableType     | exists
      ${TYPE_EPIC}     | ${false}
      ${TYPE_INCIDENT} | ${true}
      ${TYPE_ISSUE}    | ${true}
    `(`when $issuableType`, ({ issuableType, exists }) => {
      it(`${exists ? 'renders' : 'does not render'}`, () => {
        mountComponent({ issuableType });

        expect(findConvertToTaskItem().exists()).toBe(exists);
      });
    });
  });

  describe('events', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('emits event when `Convert to task` dropdown item is clicked', () => {
      findConvertToTaskItem().vm.$emit('action');

      expect(eventHub.$emit).toHaveBeenCalledWith('convert-task-list-item', '3:1-3:10');
    });

    it('emits event when `Delete` dropdown item is clicked', () => {
      findDeleteItem().vm.$emit('action');

      expect(eventHub.$emit).toHaveBeenCalledWith('delete-task-list-item', '3:1-3:10');
    });
  });
});
