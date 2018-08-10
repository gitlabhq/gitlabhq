import Vue from 'vue';

import mountComponent from 'spec/helpers/vue_mount_component_helper';

import TableBodyComponent from 'ee/group_member_contributions/components/table_body.vue';
import GroupMemberStore from 'ee/group_member_contributions/store/group_member_store';

import { rawMembers } from '../mock_data';

const createComponent = () => {
  const Component = Vue.extend(TableBodyComponent);

  const store = new GroupMemberStore();
  store.setMembers(rawMembers);
  const rows = store.members;

  return mountComponent(Component, { rows });
};

describe('TableBodyComponent', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('template', () => {
    it('renders row item element', () => {
      const rowEl = vm.$el.querySelector('tr');
      expect(rowEl).not.toBeNull();
      expect(rowEl.querySelectorAll('td').length).toBe(7);
    });

    it('renders username row cell element', () => {
      const cellEl = vm.$el.querySelector('td strong');
      expect(cellEl).not.toBeNull();
      expect(cellEl.querySelector('a').getAttribute('href')).toBe(rawMembers[0].user_web_url);
    });
  });
});
