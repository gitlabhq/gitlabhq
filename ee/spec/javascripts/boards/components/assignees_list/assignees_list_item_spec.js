import Vue from 'vue';

import AssigneesListItemComponent from 'ee/boards/components/assignees_list/assignees_list_item.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

import { mockAssigneesList } from 'spec/boards/mock_data';

const createComponent = () => {
  const Component = Vue.extend(AssigneesListItemComponent);

  return mountComponent(Component, {
    assignee: mockAssigneesList[0],
  });
};

describe('AssigneesListItemComponent', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
    describe('avatarAltText', () => {
      it('returns computed alt text based on assignee.name', () => {
        expect(vm.avatarAltText).toBe(`${mockAssigneesList[0].name}'s avatar`);
      });
    });
  });

  describe('methods', () => {
    describe('handleItemClick', () => {
      it('emits `onItemSelect` event on component and sends `assignee` as event param', () => {
        spyOn(vm, '$emit');
        const assignee = mockAssigneesList[0];

        vm.handleItemClick();
        expect(vm.$emit).toHaveBeenCalledWith('onItemSelect', assignee);
      });
    });
  });

  describe('template', () => {
    it('renders component container element with class `filter-dropdown-item`', () => {
      expect(vm.$el.classList.contains('filter-dropdown-item')).toBe(true);
    });

    it('renders user item button element', () => {
      const assignee = mockAssigneesList[0];
      const buttonEl = vm.$el.querySelector('.dropdown-user');

      expect(buttonEl).not.toBeNull();
      expect(
        buttonEl.querySelector('.avatar-container.s32 img.avatar.s32').getAttribute('src'),
      ).toBe(assignee.avatar_url);
      expect(buttonEl.querySelector('.dropdown-user-details').innerText).toContain(assignee.name);
      expect(
        buttonEl.querySelector('.dropdown-user-details .dropdown-light-content').innerText,
      ).toContain(`@${assignee.username}`);
    });
  });
});
