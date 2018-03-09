<script>
/* global Flash */

import $ from 'jquery';
import { s__ } from '~/locale';
import loadingIcon from '~/vue_shared/components/loading_icon.vue';
import modal from '~/vue_shared/components/modal.vue';
import { getParameterByName } from '~/lib/utils/common_utils';
import { mergeUrlParams } from '~/lib/utils/url_utility';

import eventHub from '../event_hub';
import { COMMON_STR } from '../constants';
import groupsComponent from './groups.vue';

export default {
  components: {
    loadingIcon,
    modal,
    groupsComponent,
  },
  props: {
    store: {
      type: Object,
      required: true,
    },
    service: {
      type: Object,
      required: true,
    },
    hideProjects: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      isLoading: true,
      isSearchEmpty: false,
      searchEmptyMessage: '',
      showModal: false,
      groupLeaveConfirmationMessage: '',
      targetGroup: null,
      targetParentGroup: null,
    };
  },
  computed: {
    groups() {
      return this.store.getGroups();
    },
    pageInfo() {
      return this.store.getPaginationInfo();
    },
  },
  created() {
    this.searchEmptyMessage = this.hideProjects ?
      COMMON_STR.GROUP_SEARCH_EMPTY : COMMON_STR.GROUP_PROJECT_SEARCH_EMPTY;

    eventHub.$on('fetchPage', this.fetchPage);
    eventHub.$on('toggleChildren', this.toggleChildren);
    eventHub.$on('showLeaveGroupModal', this.showLeaveGroupModal);
    eventHub.$on('updatePagination', this.updatePagination);
    eventHub.$on('updateGroups', this.updateGroups);
  },
  mounted() {
    this.fetchAllGroups();
  },
  beforeDestroy() {
    eventHub.$off('fetchPage', this.fetchPage);
    eventHub.$off('toggleChildren', this.toggleChildren);
    eventHub.$off('showLeaveGroupModal', this.showLeaveGroupModal);
    eventHub.$off('updatePagination', this.updatePagination);
    eventHub.$off('updateGroups', this.updateGroups);
  },
  methods: {
    fetchGroups({ parentId, page, filterGroupsBy, sortBy, archived, updatePagination }) {
      return this.service.getGroups(parentId, page, filterGroupsBy, sortBy, archived)
                .then((res) => {
                  if (updatePagination) {
                    this.updatePagination(res.headers);
                  }

                  return res;
                })
                .then(res => res.json())
                .catch(() => {
                  this.isLoading = false;
                  $.scrollTo(0);

                  Flash(COMMON_STR.FAILURE);
                });
    },
    fetchAllGroups() {
      const page = getParameterByName('page') || null;
      const sortBy = getParameterByName('sort') || null;
      const archived = getParameterByName('archived') || null;
      const filterGroupsBy = getParameterByName('filter') || null;

      this.isLoading = true;
      // eslint-disable-next-line promise/catch-or-return
      this.fetchGroups({
        page,
        filterGroupsBy,
        sortBy,
        archived,
        updatePagination: true,
      }).then((res) => {
        this.isLoading = false;
        this.updateGroups(res, Boolean(filterGroupsBy));
      });
    },
    fetchPage(page, filterGroupsBy, sortBy, archived) {
      this.isLoading = true;

      // eslint-disable-next-line promise/catch-or-return
      this.fetchGroups({
        page,
        filterGroupsBy,
        sortBy,
        archived,
        updatePagination: true,
      }).then((res) => {
        this.isLoading = false;
        $.scrollTo(0);

        const currentPath = mergeUrlParams({ page }, window.location.href);
        window.history.replaceState({
          page: currentPath,
        }, document.title, currentPath);

        this.updateGroups(res);
      });
    },
    toggleChildren(group) {
      const parentGroup = group;
      if (!parentGroup.isOpen) {
        if (parentGroup.children.length === 0) {
          parentGroup.isChildrenLoading = true;
          // eslint-disable-next-line promise/catch-or-return
          this.fetchGroups({
            parentId: parentGroup.id,
          }).then((res) => {
            this.store.setGroupChildren(parentGroup, res);
          }).catch(() => {
            parentGroup.isChildrenLoading = false;
          });
        } else {
          parentGroup.isOpen = true;
        }
      } else {
        parentGroup.isOpen = false;
      }
    },
    showLeaveGroupModal(group, parentGroup) {
      this.targetGroup = group;
      this.targetParentGroup = parentGroup;
      this.showModal = true;
      this.groupLeaveConfirmationMessage = s__(`GroupsTree|Are you sure you want to leave the "${group.fullName}" group?`);
    },
    hideLeaveGroupModal() {
      this.showModal = false;
    },
    leaveGroup() {
      this.showModal = false;
      this.targetGroup.isBeingRemoved = true;
      this.service.leaveGroup(this.targetGroup.leavePath)
        .then(res => res.json())
        .then((res) => {
          $.scrollTo(0);
          this.store.removeGroup(this.targetGroup, this.targetParentGroup);
          Flash(res.notice, 'notice');
        })
        .catch((err) => {
          let message = COMMON_STR.FAILURE;
          if (err.status === 403) {
            message = COMMON_STR.LEAVE_FORBIDDEN;
          }
          Flash(message);
          this.targetGroup.isBeingRemoved = false;
        });
    },
    updatePagination(headers) {
      this.store.setPaginationInfo(headers);
    },
    updateGroups(groups, fromSearch) {
      this.isSearchEmpty = groups ? groups.length === 0 : false;
      if (fromSearch) {
        this.store.setSearchedGroups(groups);
      } else {
        this.store.setGroups(groups);
      }
    },
  },
};
</script>

<template>
  <div>
    <loading-icon
      class="loading-animation prepend-top-20"
      size="2"
      v-if="isLoading"
      :label="s__('GroupsTree|Loading groups')"
    />
    <groups-component
      v-if="!isLoading"
      :groups="groups"
      :search-empty="isSearchEmpty"
      :search-empty-message="searchEmptyMessage"
      :page-info="pageInfo"
    />
    <modal
      v-if="showModal"
      kind="warning"
      :primary-button-label="__('Leave')"
      :title="__('Are you sure?')"
      :text="groupLeaveConfirmationMessage"
      @cancel="hideLeaveGroupModal"
      @submit="leaveGroup"
    />
  </div>
</template>
