import { GlModal, GlLoadingIcon } from '@gitlab/ui';
import AxiosMockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import appComponent from '~/groups/components/app.vue';
import eventHub from '~/groups/event_hub';
import GroupsService from '~/groups/service/groups_service';
import GroupsStore from '~/groups/store/groups_store';
import axios from '~/lib/utils/axios_utils';
import {
  HTTP_STATUS_BAD_REQUEST,
  HTTP_STATUS_FORBIDDEN,
  HTTP_STATUS_INTERNAL_SERVER_ERROR,
  HTTP_STATUS_OK,
} from '~/lib/utils/http_status';
import * as urlUtilities from '~/lib/utils/url_utility';
import setWindowLocation from 'helpers/set_window_location_helper';

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

const $toast = {
  show: jest.fn(),
};
jest.mock('~/alert');

describe('AppComponent', () => {
  let wrapper;
  let vm;
  let mock;
  let getGroupsSpy;

  const store = new GroupsStore({});
  const service = new GroupsService(mockEndpoint);

  const createShallowComponent = ({ propsData = {} } = {}) => {
    store.state.pageInfo = mockPageInfo;
    wrapper = shallowMountExtended(appComponent, {
      propsData: {
        store,
        service,
        containerId: 'js-groups-list-with-filtered-search',
        ...propsData,
      },
      scopedSlots: {
        'empty-state': '<div data-testid="empty-state" />',
      },
      mocks: {
        $toast,
      },
    });
    vm = wrapper.vm;
  };

  beforeEach(async () => {
    mock = new AxiosMockAdapter(axios);
    mock.onGet('/dashboard/groups.json').reply(HTTP_STATUS_OK, mockGroups);
    setWindowLocation('?filter=foobar');

    document.body.innerHTML = `
      <div id="js-groups-list-with-filtered-search">
        <div class="empty-state hidden" data-testid="legacy-empty-state">
          <p>There are no projects shared with this group yet</p>
        </div>
      </div>
    `;

    createShallowComponent();
    getGroupsSpy = jest.spyOn(vm.service, 'getGroups');
    await nextTick();
  });

  describe('methods', () => {
    describe('fetchGroups', () => {
      it('should call `getGroups` with all the params provided', () => {
        return vm
          .fetchGroups({
            parentId: 1,
            page: 2,
            filterGroupsBy: 'git',
            sortBy: 'created_desc',
          })
          .then(() => {
            expect(getGroupsSpy).toHaveBeenCalledWith(1, 2, 'git', 'created_desc');
          });
      });

      it('should set headers to store for building pagination info when called with `updatePagination`', () => {
        mock.onGet('/dashboard/groups.json').reply(HTTP_STATUS_OK, { headers: mockRawPageInfo });

        jest.spyOn(vm, 'updatePagination').mockImplementation(() => {});

        return vm.fetchGroups({ updatePagination: true }).then(() => {
          expect(getGroupsSpy).toHaveBeenCalled();
          expect(vm.updatePagination).toHaveBeenCalled();
        });
      });

      it('should show an alert when request fails', () => {
        mock.onGet('/dashboard/groups.json').reply(HTTP_STATUS_BAD_REQUEST);

        jest.spyOn(window, 'scrollTo').mockImplementation(() => {});
        return vm.fetchGroups({}).then(() => {
          expect(vm.isLoading).toBe(false);
          expect(window.scrollTo).toHaveBeenCalledWith({ behavior: 'smooth', top: 0 });
          expect(createAlert).toHaveBeenCalledWith({
            message: 'An error occurred. Please try again.',
          });
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
        mock.onGet('/dashboard/groups.json').reply(HTTP_STATUS_OK, mockSearchedGroups);

        const fetchPromise = vm.fetchAllGroups();

        expect(vm.fetchGroups).toHaveBeenCalledWith({
          page: null,
          filterGroupsBy: 'foobar',
          sortBy: null,
          updatePagination: true,
        });
        return fetchPromise.then(() => {
          expect(vm.updateGroups).toHaveBeenCalledWith(mockSearchedGroups, true);
        });
      });
    });

    describe('fetchPage', () => {
      beforeEach(() => {
        jest.spyOn(vm, 'fetchGroups');
        jest.spyOn(vm, 'updateGroups');
      });

      it('without filter should fetch groups for provided page details, update window state, and call setGroups', () => {
        jest.spyOn(urlUtilities, 'mergeUrlParams');
        jest.spyOn(window.history, 'replaceState').mockImplementation(() => {});
        jest.spyOn(window, 'scrollTo').mockImplementation(() => {});
        jest.spyOn(vm.store, 'setGroups').mockImplementation(() => {});

        const fetchPagePromise = vm.fetchPage({
          page: 2,
          filterGroupsBy: null,
          sortBy: null,
        });

        expect(vm.isLoading).toBe(true);
        expect(vm.fetchGroups).toHaveBeenCalledWith({
          page: 2,
          filterGroupsBy: null,
          sortBy: null,
          updatePagination: true,
        });

        return fetchPagePromise.then(() => {
          expect(vm.isLoading).toBe(false);
          expect(window.scrollTo).toHaveBeenCalledWith({ behavior: 'smooth', top: 0 });
          expect(urlUtilities.mergeUrlParams).toHaveBeenCalledWith({ page: 2 }, expect.any(String));
          expect(window.history.replaceState).toHaveBeenCalledWith(
            {
              page: expect.any(String),
            },
            expect.any(String),
            expect.any(String),
          );

          expect(vm.store.setGroups).toHaveBeenCalledWith(mockGroups);
        });
      });

      it('with filter should fetch groups for provided page details, update window state, and call setSearchedGroups', () => {
        jest.spyOn(urlUtilities, 'mergeUrlParams');
        jest.spyOn(window.history, 'replaceState').mockImplementation(() => {});
        jest.spyOn(window, 'scrollTo').mockImplementation(() => {});
        jest.spyOn(vm.store, 'setSearchedGroups').mockImplementation(() => {});

        const fetchPagePromise = vm.fetchPage({
          page: 2,
          filterGroupsBy: 'search',
          sortBy: null,
        });

        expect(vm.isLoading).toBe(true);
        expect(vm.fetchGroups).toHaveBeenCalledWith({
          page: 2,
          filterGroupsBy: 'search',
          sortBy: null,
          updatePagination: true,
        });

        return fetchPagePromise.then(() => {
          expect(vm.isLoading).toBe(false);
          expect(window.scrollTo).toHaveBeenCalledWith({ behavior: 'smooth', top: 0 });
          expect(urlUtilities.mergeUrlParams).toHaveBeenCalledWith({ page: 2 }, expect.any(String));
          expect(window.history.replaceState).toHaveBeenCalledWith(
            {
              page: expect.any(String),
            },
            expect.any(String),
            expect.any(String),
          );

          expect(vm.store.setSearchedGroups).toHaveBeenCalledWith(mockGroups);
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
        mock.onGet('/dashboard/groups.json').reply(HTTP_STATUS_OK, mockRawChildren);
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
        mock.onGet('/dashboard/groups.json').reply(HTTP_STATUS_BAD_REQUEST);

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

        expect(vm.isModalVisible).toBe(true);
        expect(vm.targetGroup).not.toBe(null);
        expect(vm.targetParentGroup).not.toBe(null);
      });

      it('updates props which show modal confirmation dialog', () => {
        const group = { ...mockParentGroupItem };

        expect(vm.groupLeaveConfirmationMessage).toBe('');
        vm.showLeaveGroupModal(group, mockParentGroupItem);

        expect(vm.isModalVisible).toBe(true);
        expect(vm.groupLeaveConfirmationMessage).toBe(
          `Are you sure you want to leave the "${group.fullName}" group?`,
        );
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
        jest.spyOn(window, 'scrollTo').mockImplementation(() => {});

        vm.leaveGroup();

        expect(vm.targetGroup.isBeingRemoved).toBe(true);
        expect(vm.service.leaveGroup).toHaveBeenCalledWith(vm.targetGroup.leavePath);
        return waitForPromises().then(() => {
          expect(window.scrollTo).toHaveBeenCalledWith({ behavior: 'smooth', top: 0 });
          expect(vm.store.removeGroup).toHaveBeenCalledWith(vm.targetGroup, vm.targetParentGroup);
          expect($toast.show).toHaveBeenCalledWith(notice);
        });
      });

      it('should show error alert if request failed to leave group', () => {
        const message = 'An error occurred. Please try again.';
        jest
          .spyOn(vm.service, 'leaveGroup')
          .mockRejectedValue({ status: HTTP_STATUS_INTERNAL_SERVER_ERROR });
        jest.spyOn(vm.store, 'removeGroup');
        vm.leaveGroup();

        expect(vm.targetGroup.isBeingRemoved).toBe(true);
        expect(vm.service.leaveGroup).toHaveBeenCalledWith(childGroupItem.leavePath);
        return waitForPromises().then(() => {
          expect(vm.store.removeGroup).not.toHaveBeenCalled();
          expect(createAlert).toHaveBeenCalledWith({ message });
          expect(vm.targetGroup.isBeingRemoved).toBe(false);
        });
      });

      it('shows appropriate error alert if request forbids to leave group', () => {
        const message = 'Failed to leave the group. Please make sure you are not the only owner.';
        jest.spyOn(vm.service, 'leaveGroup').mockRejectedValue({ status: HTTP_STATUS_FORBIDDEN });
        jest.spyOn(vm.store, 'removeGroup');
        vm.leaveGroup(childGroupItem, groupItem);

        expect(vm.targetGroup.isBeingRemoved).toBe(true);
        expect(vm.service.leaveGroup).toHaveBeenCalledWith(childGroupItem.leavePath);
        return waitForPromises().then(() => {
          expect(vm.store.removeGroup).not.toHaveBeenCalled();
          expect(createAlert).toHaveBeenCalledWith({ message });
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

      describe.each`
        groups        | fromSearch | shouldRenderEmptyState | shouldRenderSearchEmptyState
        ${[]}         | ${false}   | ${true}                | ${false}
        ${mockGroups} | ${false}   | ${false}               | ${false}
        ${[]}         | ${true}    | ${false}               | ${true}
      `(
        'when `groups` is $groups, and `fromSearch` is $fromSearch',
        ({ groups, fromSearch, shouldRenderEmptyState, shouldRenderSearchEmptyState }) => {
          it(`${shouldRenderEmptyState ? 'renders' : 'does not render'} empty state`, async () => {
            createShallowComponent();

            await waitForPromises();

            vm.updateGroups(groups, fromSearch);

            await nextTick();

            expect(wrapper.findByTestId('empty-state').exists()).toBe(shouldRenderEmptyState);
            expect(wrapper.findByTestId('search-empty-state').exists()).toBe(
              shouldRenderSearchEmptyState,
            );
          });
        },
      );
    });
  });

  describe('created', () => {
    it('should bind event listeners on eventHub', async () => {
      jest.spyOn(eventHub, '$on').mockImplementation(() => {});

      createShallowComponent();

      await nextTick();
      expect(eventHub.$on).toHaveBeenCalledWith('fetchPage', expect.any(Function));
      expect(eventHub.$on).toHaveBeenCalledWith('toggleChildren', expect.any(Function));
      expect(eventHub.$on).toHaveBeenCalledWith('showLeaveGroupModal', expect.any(Function));
      expect(eventHub.$on).toHaveBeenCalledWith(
        'fetchFilteredAndSortedGroups',
        expect.any(Function),
      );
    });
  });

  describe('beforeDestroy', () => {
    it('should unbind event listeners on eventHub', async () => {
      jest.spyOn(eventHub, '$off').mockImplementation(() => {});

      createShallowComponent();
      wrapper.destroy();

      await nextTick();
      expect(eventHub.$off).toHaveBeenCalledWith('fetchPage', expect.any(Function));
      expect(eventHub.$off).toHaveBeenCalledWith('toggleChildren', expect.any(Function));
      expect(eventHub.$off).toHaveBeenCalledWith('showLeaveGroupModal', expect.any(Function));
      expect(eventHub.$off).toHaveBeenCalledWith(
        'fetchFilteredAndSortedGroups',
        expect.any(Function),
      );
    });
  });

  describe('when `fetchFilteredAndSortedGroups` event is emitted', () => {
    const search = 'Foo bar';
    const sort = 'created_asc';
    const emitFetchFilteredAndSortedGroups = () => {
      eventHub.$emit('fetchFilteredAndSortedGroups', {
        filterGroupsBy: search,
        sortBy: sort,
      });
    };
    let setPaginationInfoSpy;

    beforeEach(() => {
      setPaginationInfoSpy = jest.spyOn(GroupsStore.prototype, 'setPaginationInfo');
      createShallowComponent();
    });

    it('renders loading icon', async () => {
      emitFetchFilteredAndSortedGroups();
      await nextTick();

      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
    });

    it('calls API with expected params', () => {
      emitFetchFilteredAndSortedGroups();

      expect(getGroupsSpy).toHaveBeenCalledWith(undefined, undefined, search, sort);
    });

    it('updates pagination', () => {
      emitFetchFilteredAndSortedGroups();

      expect(setPaginationInfoSpy).toHaveBeenCalled();
    });
  });

  describe('template', () => {
    it('should render loading icon', async () => {
      vm.isLoading = true;
      await nextTick();
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
    });

    it('should render groups tree', async () => {
      vm.store.state.groups = [mockParentGroupItem];
      vm.isLoading = false;
      await nextTick();
      expect(vm.$el.querySelector('.groups-list-tree-container')).toBeDefined();
    });

    it('renders modal confirmation dialog', () => {
      createShallowComponent();

      const findGlModal = wrapper.findComponent(GlModal);

      expect(findGlModal.exists()).toBe(true);
      expect(findGlModal.attributes('title')).toBe('Are you sure?');
      expect(findGlModal.props('actionPrimary').text).toBe('Leave group');
    });
  });
});
