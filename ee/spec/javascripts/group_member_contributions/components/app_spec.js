import Vue from 'vue';

import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';

import mountComponent from 'spec/helpers/vue_mount_component_helper';

import AppComponent from 'ee/group_member_contributions/components/app.vue';
import GroupMemberStore from 'ee/group_member_contributions/store/group_member_store';
import GroupMemberService from 'ee/group_member_contributions/service/group_member_service';
import { contributionsPath, rawMembers } from '../mock_data';

const createComponent = () => {
  const Component = Vue.extend(AppComponent);

  const store = new GroupMemberStore();
  const service = new GroupMemberService(contributionsPath);

  return mountComponent(Component, {
    store,
    service,
  });
};

describe('AppComponent', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('methods', () => {
    describe('fetchContributedMembers', () => {
      let mock;

      beforeEach(() => {
        mock = new MockAdapter(axios);
        document.body.innerHTML += '<div class="flash-container"></div>';
      });

      afterEach(() => {
        mock.restore();
        document.querySelector('.flash-container').remove();
      });

      it('calls service.getContributedMembers and sets response to the store on success', done => {
        mock.onGet(vm.service.memberContributionsPath).reply(200, rawMembers);
        spyOn(vm.store, 'setColumns');
        spyOn(vm.store, 'setMembers');

        vm.fetchContributedMembers();
        expect(vm.isLoading).toBe(true);
        setTimeout(() => {
          expect(vm.isLoading).toBe(false);
          expect(vm.store.setColumns).toHaveBeenCalledWith(jasmine.any(Object));
          expect(vm.store.setMembers).toHaveBeenCalledWith(rawMembers);
          done();
        }, 0);
      });

      it('calls service.getContributedMembers and sets `isLoading` to false and shows flash message if request failed', done => {
        mock.onGet(vm.service.memberContributionsPath).reply(500, {});

        vm.fetchContributedMembers();
        expect(vm.isLoading).toBe(true);
        setTimeout(() => {
          expect(vm.isLoading).toBe(false);
          expect(document.querySelector('.flash-text').innerText.trim()).toBe(
            'Something went wrong while fetching group member contributions',
          );
          done();
        }, 0);
      });
    });

    describe('handleColumnClick', () => {
      it('calls store.sortMembers with columnName param', () => {
        spyOn(vm.store, 'sortMembers');

        const columnName = 'fullname';
        vm.handleColumnClick(columnName);
        expect(vm.store.sortMembers).toHaveBeenCalledWith(columnName);
      });
    });
  });

  describe('template', () => {
    it('renders component container element with class `group-member-contributions-container`', () => {
      expect(vm.$el.classList.contains('group-member-contributions-container')).toBe(true);
    });

    it('renders header title element within component containe', () => {
      expect(vm.$el.querySelector('h3').innerText.trim()).toBe('Contributions per group member');
    });

    it('shows loading icon when isLoading prop is true', done => {
      vm.isLoading = true;
      vm
        .$nextTick()
        .then(() => {
          const loadingEl = vm.$el.querySelector('.loading-animation');
          expect(loadingEl).not.toBeNull();
          expect(loadingEl.querySelector('i').getAttribute('aria-label')).toBe(
            'Loading contribution stats for group members',
          );
        })
        .then(done)
        .catch(done.fail);
    });

    it('renders table container element', done => {
      vm.isLoading = false;
      vm
        .$nextTick()
        .then(() => {
          expect(vm.$el.querySelector('table.table.gl-sortable')).not.toBeNull();
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
