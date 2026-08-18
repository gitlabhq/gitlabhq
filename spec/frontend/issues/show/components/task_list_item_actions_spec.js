import { GlDisclosureDropdown } from '@gitlab/ui';
import { setHTMLFixture } from 'helpers/fixtures';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { TYPE_INCIDENT, TYPE_ISSUE } from '~/issues/constants';
import TaskListItemActions from '~/issues/show/components/task_list_item_actions.vue';
import eventHub from '~/issues/show/event_hub';
import { WORK_ITEM_TYPE_NAME_EPIC, WORK_ITEM_TYPE_NAME_TASK } from '~/work_items/constants';

jest.mock('~/issues/show/event_hub');

describe('TaskListItemActions component', () => {
  let wrapper;

  const findGlDisclosureDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findConvertToChildItemItem = () => wrapper.findComponentByTestId('convert');
  const findDeleteItem = () => wrapper.findComponentByTestId('delete');
  const findDisableItem = () => wrapper.findComponentByTestId('disable');
  const findEnableItem = () => wrapper.findComponentByTestId('enable');

  const mountComponent = ({ issuableType = TYPE_ISSUE, enabled = true } = {}) => {
    setHTMLFixture(`
      <li data-sourcepos="3:1-3:10">
        <div></div>
      </li>
    `);

    wrapper = shallowMountExtended(TaskListItemActions, {
      provide: {
        id: 'gid://gitlab/WorkItem/818',
        issuableType,
        enabled,
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
      size: 'small',
      textSrOnly: true,
      toggleText: 'Checklist item actions',
    });
  });

  describe('active row highlight', () => {
    it('adds active class to the parent list item when the dropdown is shown', () => {
      mountComponent();

      findGlDisclosureDropdown().vm.$emit('shown');

      expect(document.querySelector('li').classList.contains('task-list-item-active')).toBe(true);
    });

    it('removes active class from the parent list item when the dropdown is hidden', () => {
      mountComponent();
      findGlDisclosureDropdown().vm.$emit('shown');

      findGlDisclosureDropdown().vm.$emit('hidden');

      expect(document.querySelector('li').classList.contains('task-list-item-active')).toBe(false);
    });
  });

  describe('"Convert to child item" dropdown item', () => {
    describe.each`
      issuableType                | exists
      ${TYPE_INCIDENT}            | ${true}
      ${TYPE_ISSUE}               | ${true}
      ${WORK_ITEM_TYPE_NAME_EPIC} | ${true}
      ${WORK_ITEM_TYPE_NAME_TASK} | ${false}
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

  describe('events for enabled items', () => {
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
    it('emits event when `Disable` dropdown item is clicked', () => {
      findDisableItem().vm.$emit('action');

      expect(eventHub.$emit).toHaveBeenCalledWith('disable-task-list-item', {
        id: 'gid://gitlab/WorkItem/818',
        sourcepos: '3:1-3:10',
      });
    });
  });

  describe('events for disabled items', () => {
    beforeEach(() => {
      mountComponent({ enabled: false });
    });

    it('emits event when `Delete` dropdown item is clicked', () => {
      findDeleteItem().vm.$emit('action');

      expect(eventHub.$emit).toHaveBeenCalledWith('delete-task-list-item', {
        id: 'gid://gitlab/WorkItem/818',
        sourcepos: '3:1-3:10',
      });
    });
    it('emits event when `Enable` dropdown item is clicked', () => {
      findEnableItem().vm.$emit('action');

      expect(eventHub.$emit).toHaveBeenCalledWith('enable-task-list-item', {
        id: 'gid://gitlab/WorkItem/818',
        sourcepos: '3:1-3:10',
      });
    });
  });
});
