import { GlDisclosureDropdown } from '@gitlab/ui';
import { setHTMLFixture } from 'helpers/fixtures';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { TYPE_INCIDENT, TYPE_ISSUE } from '~/issues/constants';
import TaskListItemActions from '~/issues/show/components/task_list_item_actions.vue';
import eventHub from '~/issues/show/event_hub';
import { WORK_ITEM_TYPE_VALUE_EPIC, WORK_ITEM_TYPE_VALUE_TASK } from '~/work_items/constants';

jest.mock('~/issues/show/event_hub');

describe('TaskListItemActions component', () => {
  let wrapper;

  const findGlDisclosureDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findConvertToChildItemItem = () => wrapper.findByTestId('convert');
  const findDeleteItem = () => wrapper.findByTestId('delete');

  const mountComponent = ({ issuableType = TYPE_ISSUE } = {}) => {
    setHTMLFixture(`
      <li data-sourcepos="3:1-3:10">
        <div></div>
      </li>
    `);

    wrapper = shallowMountExtended(TaskListItemActions, {
      provide: {
        id: 'gid://gitlab/WorkItem/818',
        issuableType,
      },
      attachTo: 'div',
    });
  };

  it('renders dropdown', () => {
    mountComponent();

    expect(findGlDisclosureDropdown().props()).toMatchObject({
      category: 'tertiary',
      icon: 'ellipsis_v',
      placement: 'bottom-end',
      textSrOnly: true,
      toggleText: 'Task actions',
    });
  });

  describe('"Convert to child item" dropdown item', () => {
    describe.each`
      issuableType                 | exists
      ${TYPE_INCIDENT}             | ${true}
      ${TYPE_ISSUE}                | ${true}
      ${WORK_ITEM_TYPE_VALUE_EPIC} | ${true}
      ${WORK_ITEM_TYPE_VALUE_TASK} | ${false}
    `(`when $issuableType`, ({ issuableType, exists }) => {
      it(`${exists ? 'renders' : 'does not render'}`, () => {
        mountComponent({ issuableType });

        expect(findConvertToChildItemItem().exists()).toBe(exists);
      });
    });

    it('has text', () => {
      mountComponent();

      expect(findConvertToChildItemItem().text()).toBe('Convert to child item');
    });
  });

  describe('events', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('emits event when `Convert to child item` dropdown item is clicked', () => {
      findConvertToChildItemItem().vm.$emit('action');

      expect(eventHub.$emit).toHaveBeenCalledWith('convert-task-list-item', {
        id: 'gid://gitlab/WorkItem/818',
        sourcepos: '3:1-3:10',
      });
    });

    it('emits event when `Delete` dropdown item is clicked', () => {
      findDeleteItem().vm.$emit('action');

      expect(eventHub.$emit).toHaveBeenCalledWith('delete-task-list-item', {
        id: 'gid://gitlab/WorkItem/818',
        sourcepos: '3:1-3:10',
      });
    });
  });
});
