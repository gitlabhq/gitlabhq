import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import TaskListItemActions from '~/issues/show/components/task_list_item_actions.vue';
import eventHub from '~/issues/show/event_hub';

describe('TaskListItemActions component', () => {
  let wrapper;

  const findGlDropdown = () => wrapper.findComponent(GlDropdown);
  const findConvertToTaskItem = () => wrapper.findAllComponents(GlDropdownItem).at(0);
  const findDeleteItem = () => wrapper.findAllComponents(GlDropdownItem).at(1);

  const mountComponent = () => {
    const li = document.createElement('li');
    li.dataset.sourcepos = '3:1-3:10';
    li.appendChild(document.createElement('div'));
    document.body.appendChild(li);

    wrapper = shallowMount(TaskListItemActions, {
      provide: { canUpdate: true },
      attachTo: document.querySelector('div'),
    });
  };

  beforeEach(() => {
    mountComponent();
  });

  it('renders dropdown', () => {
    expect(findGlDropdown().props()).toMatchObject({
      category: 'tertiary',
      icon: 'ellipsis_v',
      right: true,
      text: TaskListItemActions.i18n.taskActions,
      textSrOnly: true,
    });
  });

  it('emits event when `Convert to task` dropdown item is clicked', () => {
    jest.spyOn(eventHub, '$emit');

    findConvertToTaskItem().vm.$emit('click');

    expect(eventHub.$emit).toHaveBeenCalledWith('convert-task-list-item', '3:1-3:10');
  });

  it('emits event when `Delete` dropdown item is clicked', () => {
    jest.spyOn(eventHub, '$emit');

    findDeleteItem().vm.$emit('click');

    expect(eventHub.$emit).toHaveBeenCalledWith('delete-task-list-item', '3:1-3:10');
  });
});
