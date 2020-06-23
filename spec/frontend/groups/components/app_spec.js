import '~/flash';
import $ from 'jquery';
import Vue from 'vue';
import AxiosMockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import waitForPromises from 'helpers/wait_for_promises';
import appComponent from '~/groups/components/app.vue';
import groupFolderComponent from '~/groups/components/group_folder.vue';
import groupItemComponent from '~/groups/components/group_item.vue';
import eventHub from '~/groups/event_hub';
import GroupsStore from '~/groups/store/groups_store';
import GroupsService from '~/groups/service/groups_service';
import * as urlUtilities from '~/lib/utils/url_utility';

import {
  mockEndpoint,
  mockGroups,
  mockSearchedGroups,
  mockRawPageInfo,
  mockParentGroupItem,
  mockRawChildren,
  mockChildren,
  mockPageInfo,
} from '../mock_data';

const createComponent = (hideProjects = false) => {
  const Component = Vue.extend(appComponent);
  const store = new GroupsStore(false);
  const service = new GroupsService(mockEndpoint);

  store.state.pageInfo = mockPageInfo;

  return new Component({
    propsData: {
      store,
      service,
      hideProjects,
    },
  });
};

describe('AppComponent', () => {
  let vm;
  let mock;
  let getGroupsSpy;

  beforeEach(() => {
    mock = new AxiosMockAdapter(axios);
    mock.onGet('/dashboard/groups.json').reply(200, mockGroups);
    Vue.component('group-folder', groupFolderComponent);
    Vue.component('group-item', groupItemComponent);

    vm = createComponent();
    getGroupsSpy = jest.spyOn(vm.service, 'getGroups');
    return vm.$nextTick();
  });

  describe('computed', () => {
    beforeEach(() => {
      vm.$mount();
    });

    afterEach(() => {
      vm.$destroy();
    });

    describe('groups', () => {
      it('should return list of groups from store', () => {
        jest.spyOn(vm.store, 'getGroups').mockImplementation(() => {});

        const { groups } = vm;

        expect(vm.store.getGroups).toHaveBeenCalled();
        expect(groups).not.toBeDefined();
      });
    });

    describe('pageInfo', () => {
      it('should return pagination info from store', () => {
        jest.spyOn(vm.store, 'getPaginationInfo').mockImplementation(() => {});

        const { pageInfo } = vm;

        expect(vm.store.getPaginationInfo).toHaveBeenCalled();
        expect(pageInfo).not.toBeDefined();
      });
    });
  });

  describe('methods', () => {
    beforeEach(() => {
      vm.$mount();
    });

    afterEach(() => {
      vm.$destroy();
    });

    describe('fetchGroups', () => {
      it('should call `getGroups` with all the params provided', () => {
        return vm
          .fetchGroups({
            parentId: 1,
            page: 2,
            filterGroupsBy: 'git',
            sortBy: 'created_desc',
            archived: true,
          })
          .then(() => {
            expect(getGroupsSpy).toHaveBeenCalledWith(1, 2, 'git', 'created_desc', true);
          });
      });

      it('should set headers to store for building pagination info when called with `updatePagination`', () => {
        mock.onGet('/dashboard/groups.json').reply(200, { headers: mockRawPageInfo });

        jest.spyOn(vm, 'updatePagination').mockImplementation(() => {});

        return vm.fetchGroups({ updatePagination: true }).then(() => {
          expect(getGroupsSpy).toHaveBeenCalled();
          expect(vm.updatePagination).toHaveBeenCalled();
        });
      });

      it('should show flash error when request fails', () => {
        mock.onGet('/dashboard/groups.json').reply(400);

        jest.spyOn($, 'scrollTo').mockImplementation(() => {});
        jest.spyOn(window, 'Flash').mockImplementation(() => {});

        return vm.fetchGroups({}).then(() => {
          expect(vm.isLoading).toBe(false);
          expect($.scrollTo).toHaveBeenCalledWith(0);
          expect(window.Flash).toHaveBeenCalledWith('An error occurred. Please try again.');
        });
      });
    });

    describe('fetchAllGroups', () => {
      beforeEach(() => {
        jest.spyOn(vm, 'fetchGroups');
        jest.spyOn(vm, 'updateGroups');
      });

      it('should fetch default set of groups', () => {
        jest.spyOn(vm, 'updatePagination');

        const fetchPromise = vm.fetchAllGroups();

        expect(vm.isLoading).toBe(true);

        return fetchPromise.then(() => {
          expect(vm.isLoading).toBe(false);
          expect(vm.updateGroups).toHaveBeenCalled();
        });
      });

      it('should fetch matching set of groups when app is loaded with search query', () => {
        mock.onGet('/dashboard/groups.json').reply(200, mockSearchedGroups);

        const fetchPromise = vm.fetchAllGroups();

        expect(vm.fetchGroups).toHaveBeenCalledWith({
          page: null,
          filterGroupsBy: null,
          sortBy: null,
          updatePagination: true,
          archived: null,
        });
        return fetchPromise.then(() => {
          expect(vm.updateGroups).toHaveBeenCalled();
        });
      });
    });

    describe('fetchPage', () => {
      beforeEach(() => {
        jest.spyOn(vm, 'fetchGroups');
        jest.spyOn(vm, 'updateGroups');
      });

      it('should fetch groups for provided page details and update window state', () => {
        jest.spyOn(urlUtilities, 'mergeUrlParams');
        jest.spyOn(window.history, 'replaceState').mockImplementation(() => {});
        jest.spyOn($, 'scrollTo').mockImplementation(() => {});

        const fetchPagePromise = vm.fetchPage(2, null, null, true);

        expect(vm.isLoading).toBe(true);
        expect(vm.fetchGroups).toHaveBeenCalledWith({
          page: 2,
          filterGroupsBy: null,
          sortBy: null,
          updatePagination: true,
          archived: true,
        });

        return fetchPagePromise.then(() => {
          expect(vm.isLoading).toBe(false);
          expect($.scrollTo).toHaveBeenCalledWith(0);
          expect(urlUtilities.mergeUrlParams).toHaveBeenCalledWith({ page: 2 }, expect.any(String));
          expect(window.history.replaceState).toHaveBeenCalledWith(
            {
              page: expect.any(String),
            },
            expect.any(String),
            expect.any(String),
          );

          expect(vm.updateGroups).toHaveBeenCalled();
        });
      });
    });

    describe('toggleChildren', () => {
      let groupItem;

      beforeEach(() => {
        groupItem = { ...mockParentGroupItem };
        groupItem.isOpen = false;
        groupItem.isChildrenLoading = false;
      });

      it('should fetch children of given group and expand it if group is collapsed and children are not loaded', () => {
        mock.onGet('/dashboard/groups.json').reply(200, mockRawChildren);
        jest.spyOn(vm, 'fetchGroups');
        jest.spyOn(vm.store, 'setGroupChildren').mockImplementation(() => {});

        vm.toggleChildren(groupItem);

        expect(groupItem.isChildrenLoading).toBe(true);
        expect(vm.fetchGroups).toHaveBeenCalledWith({
          parentId: groupItem.id,
        });
        return waitForPromises().then(() => {
          expect(vm.store.setGroupChildren).toHaveBeenCalled();
        });
      });

      it('should skip network request while expanding group if children are already loaded', () => {
        jest.spyOn(vm, 'fetchGroups');
        groupItem.children = mockRawChildren;

        vm.toggleChildren(groupItem);

        expect(vm.fetchGroups).not.toHaveBeenCalled();
        expect(groupItem.isOpen).toBe(true);
      });

      it('should collapse group if it is already expanded', () => {
        jest.spyOn(vm, 'fetchGroups');
        groupItem.isOpen = true;

        vm.toggleChildren(groupItem);

        expect(vm.fetchGroups).not.toHaveBeenCalled();
        expect(groupItem.isOpen).toBe(false);
      });

      it('should set `isChildrenLoading` back to `false` if load request fails', () => {
        mock.onGet('/dashboard/groups.json').reply(400);

        vm.toggleChildren(groupItem);

        expect(groupItem.isChildrenLoading).toBe(true);
        return waitForPromises().then(() => {
          expect(groupItem.isChildrenLoading).toBe(false);
        });
      });
    });

    describe('showLeaveGroupModal', () => {
      it('caches candidate group (as props) which is to be left', () => {
        const group = { ...mockParentGroupItem };

        expect(vm.targetGroup).toBe(null);
        expect(vm.targetParentGroup).toBe(null);
        vm.showLeaveGroupModal(group, mockParentGroupItem);

        expect(vm.targetGroup).not.toBe(null);
        expect(vm.targetParentGroup).not.toBe(null);
      });

      it('updates props which show modal confirmation dialog', () => {
        const group = { ...mockParentGroupItem };

        expect(vm.showModal).toBe(false);
        expect(vm.groupLeaveConfirmationMessage).toBe('');
        vm.showLeaveGroupModal(group, mockParentGroupItem);

        expect(vm.showModal).toBe(true);
        expect(vm.groupLeaveConfirmationMessage).toBe(
          `Are you sure you want to leave the "${group.fullName}" group?`,
        );
      });
    });

    describe('hideLeaveGroupModal', () => {
      it('hides modal confirmation which is shown before leaving the group', () => {
        const group = { ...mockParentGroupItem };
        vm.showLeaveGroupModal(group, mockParentGroupItem);

        expect(vm.showModal).toBe(true);
        vm.hideLeaveGroupModal();

        expect(vm.showModal).toBe(false);
      });
    });

    describe('leaveGroup', () => {
      let groupItem;
      let childGroupItem;

      beforeEach(() => {
        groupItem = { ...mockParentGroupItem };
        groupItem.children = mockChildren;
        [childGroupItem] = groupItem.children;
        groupItem.isChildrenLoading = false;
        vm.targetGroup = childGroupItem;
        vm.targetParentGroup = groupItem;
      });

      it('hides modal confirmation leave group and remove group item from tree', () => {
        const notice = `You left the "${childGroupItem.fullName}" group.`;
        jest.spyOn(vm.service, 'leaveGroup').mockResolvedValue({ data: { notice } });
        jest.spyOn(vm.store, 'removeGroup');
        jest.spyOn(window, 'Flash').mockImplementation(() => {});
        jest.spyOn($, 'scrollTo').mockImplementation(() => {});

        vm.leaveGroup();

        expect(vm.showModal).toBe(false);
        expect(vm.targetGroup.isBeingRemoved).toBe(true);
        expect(vm.service.leaveGroup).toHaveBeenCalledWith(vm.targetGroup.leavePath);
        return waitForPromises().then(() => {
          expect($.scrollTo).toHaveBeenCalledWith(0);
          expect(vm.store.removeGroup).toHaveBeenCalledWith(vm.targetGroup, vm.targetParentGroup);
          expect(window.Flash).toHaveBeenCalledWith(notice, 'notice');
        });
      });

      it('should show error flash message if request failed to leave group', () => {
        const message = 'An error occurred. Please try again.';
        jest.spyOn(vm.service, 'leaveGroup').mockRejectedValue({ status: 500 });
        jest.spyOn(vm.store, 'removeGroup');
        jest.spyOn(window, 'Flash').mockImplementation(() => {});

        vm.leaveGroup();

        expect(vm.targetGroup.isBeingRemoved).toBe(true);
        expect(vm.service.leaveGroup).toHaveBeenCalledWith(childGroupItem.leavePath);
        return waitForPromises().then(() => {
          expect(vm.store.removeGroup).not.toHaveBeenCalled();
          expect(window.Flash).toHaveBeenCalledWith(message);
          expect(vm.targetGroup.isBeingRemoved).toBe(false);
        });
      });

      it('should show appropriate error flash message if request forbids to leave group', () => {
        const message = 'Failed to leave the group. Please make sure you are not the only owner.';
        jest.spyOn(vm.service, 'leaveGroup').mockRejectedValue({ status: 403 });
        jest.spyOn(vm.store, 'removeGroup');
        jest.spyOn(window, 'Flash').mockImplementation(() => {});

        vm.leaveGroup(childGroupItem, groupItem);

        expect(vm.targetGroup.isBeingRemoved).toBe(true);
        expect(vm.service.leaveGroup).toHaveBeenCalledWith(childGroupItem.leavePath);
        return waitForPromises().then(() => {
          expect(vm.store.removeGroup).not.toHaveBeenCalled();
          expect(window.Flash).toHaveBeenCalledWith(message);
          expect(vm.targetGroup.isBeingRemoved).toBe(false);
        });
      });
    });

    describe('updatePagination', () => {
      it('should set pagination info to store from provided headers', () => {
        jest.spyOn(vm.store, 'setPaginationInfo').mockImplementation(() => {});

        vm.updatePagination(mockRawPageInfo);

        expect(vm.store.setPaginationInfo).toHaveBeenCalledWith(mockRawPageInfo);
      });
    });

    describe('updateGroups', () => {
      it('should call setGroups on store if method was called directly', () => {
        jest.spyOn(vm.store, 'setGroups').mockImplementation(() => {});

        vm.updateGroups(mockGroups);

        expect(vm.store.setGroups).toHaveBeenCalledWith(mockGroups);
      });

      it('should call setSearchedGroups on store if method was called with fromSearch param', () => {
        jest.spyOn(vm.store, 'setSearchedGroups').mockImplementation(() => {});

        vm.updateGroups(mockGroups, true);

        expect(vm.store.setSearchedGroups).toHaveBeenCalledWith(mockGroups);
      });

      it('should set `isSearchEmpty` prop based on groups count', () => {
        vm.updateGroups(mockGroups);

        expect(vm.isSearchEmpty).toBe(false);

        vm.updateGroups([]);

        expect(vm.isSearchEmpty).toBe(true);
      });
    });
  });

  describe('created', () => {
    it('should bind event listeners on eventHub', () => {
      jest.spyOn(eventHub, '$on').mockImplementation(() => {});

      const newVm = createComponent();
      newVm.$mount();

      return vm.$nextTick().then(() => {
        expect(eventHub.$on).toHaveBeenCalledWith('fetchPage', expect.any(Function));
        expect(eventHub.$on).toHaveBeenCalledWith('toggleChildren', expect.any(Function));
        expect(eventHub.$on).toHaveBeenCalledWith('showLeaveGroupModal', expect.any(Function));
        expect(eventHub.$on).toHaveBeenCalledWith('updatePagination', expect.any(Function));
        expect(eventHub.$on).toHaveBeenCalledWith('updateGroups', expect.any(Function));
        newVm.$destroy();
      });
    });

    it('should initialize `searchEmptyMessage` prop with correct string when `hideProjects` is `false`', () => {
      const newVm = createComponent();
      newVm.$mount();
      return vm.$nextTick().then(() => {
        expect(newVm.searchEmptyMessage).toBe('No groups or projects matched your search');
        newVm.$destroy();
      });
    });

    it('should initialize `searchEmptyMessage` prop with correct string when `hideProjects` is `true`', () => {
      const newVm = createComponent(true);
      newVm.$mount();
      return vm.$nextTick().then(() => {
        expect(newVm.searchEmptyMessage).toBe('No groups matched your search');
        newVm.$destroy();
      });
    });
  });

  describe('beforeDestroy', () => {
    it('should unbind event listeners on eventHub', () => {
      jest.spyOn(eventHub, '$off').mockImplementation(() => {});

      const newVm = createComponent();
      newVm.$mount();
      newVm.$destroy();

      return vm.$nextTick().then(() => {
        expect(eventHub.$off).toHaveBeenCalledWith('fetchPage', expect.any(Function));
        expect(eventHub.$off).toHaveBeenCalledWith('toggleChildren', expect.any(Function));
        expect(eventHub.$off).toHaveBeenCalledWith('showLeaveGroupModal', expect.any(Function));
        expect(eventHub.$off).toHaveBeenCalledWith('updatePagination', expect.any(Function));
        expect(eventHub.$off).toHaveBeenCalledWith('updateGroups', expect.any(Function));
      });
    });
  });

  describe('template', () => {
    beforeEach(() => {
      vm.$mount();
    });

    afterEach(() => {
      vm.$destroy();
    });

    it('should render loading icon', () => {
      vm.isLoading = true;
      return vm.$nextTick().then(() => {
        expect(vm.$el.querySelector('.loading-animation')).toBeDefined();
        expect(vm.$el.querySelector('span').getAttribute('aria-label')).toBe('Loading groups');
      });
    });

    it('should render groups tree', () => {
      vm.store.state.groups = [mockParentGroupItem];
      vm.isLoading = false;
      return vm.$nextTick().then(() => {
        expect(vm.$el.querySelector('.groups-list-tree-container')).toBeDefined();
      });
    });

    it('renders modal confirmation dialog', () => {
      vm.groupLeaveConfirmationMessage = 'Are you sure you want to leave the "foo" group?';
      vm.showModal = true;
      return vm.$nextTick().then(() => {
        const modalDialogEl = vm.$el.querySelector('.modal');

        expect(modalDialogEl).not.toBe(null);
        expect(modalDialogEl.querySelector('.modal-title').innerText.trim()).toBe('Are you sure?');
        expect(modalDialogEl.querySelector('.btn.btn-warning').innerText.trim()).toBe('Leave');
      });
    });
  });
});
