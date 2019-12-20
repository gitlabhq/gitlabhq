<script>
/* global Flash */

import $ from 'jquery';
import { GlLoadingIcon } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import DeprecatedModal from '~/vue_shared/components/deprecated_modal.vue';
import { HIDDEN_CLASS } from '~/lib/utils/constants';
import { getParameterByName } from '~/lib/utils/common_utils';
import { mergeUrlParams } from '~/lib/utils/url_utility';

import eventHub from '../event_hub';
import { COMMON_STR, CONTENT_LIST_CLASS } from '../constants';
import groupsComponent from './groups.vue';

export default {
  components: {
    DeprecatedModal,
    groupsComponent,
    GlLoadingIcon,
  },
  props: {
    action: {
      type: String,
      required: false,
      default: '',
    },
    containerId: {
      type: String,
      required: false,
      default: '',
    },
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
    this.searchEmptyMessage = this.hideProjects
      ? COMMON_STR.GROUP_SEARCH_EMPTY
      : COMMON_STR.GROUP_PROJECT_SEARCH_EMPTY;

    eventHub.$on(`${this.action}fetchPage`, this.fetchPage);
    eventHub.$on(`${this.action}toggleChildren`, this.toggleChildren);
    eventHub.$on(`${this.action}showLeaveGroupModal`, this.showLeaveGroupModal);
    eventHub.$on(`${this.action}updatePagination`, this.updatePagination);
    eventHub.$on(`${this.action}updateGroups`, this.updateGroups);
  },
  mounted() {
    this.fetchAllGroups();

    if (this.containerId) {
      this.containerEl = document.getElementById(this.containerId);
    }
  },
  beforeDestroy() {
    eventHub.$off(`${this.action}fetchPage`, this.fetchPage);
    eventHub.$off(`${this.action}toggleChildren`, this.toggleChildren);
    eventHub.$off(`${this.action}showLeaveGroupModal`, this.showLeaveGroupModal);
    eventHub.$off(`${this.action}updatePagination`, this.updatePagination);
    eventHub.$off(`${this.action}updateGroups`, this.updateGroups);
  },
  methods: {
    fetchGroups({ parentId, page, filterGroupsBy, sortBy, archived, updatePagination }) {
      return this.service
        .getGroups(parentId, page, filterGroupsBy, sortBy, archived)
        .then(res => {
          if (updatePagination) {
            this.updatePagination(res.headers);
          }
          return res.data;
        })
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
      }).then(res => {
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
      }).then(res => {
        this.isLoading = false;
        $.scrollTo(0);

        const currentPath = mergeUrlParams({ page }, window.location.href);
        window.history.replaceState(
          {
            page: currentPath,
          },
          document.title,
          currentPath,
        );

        this.updateGroups(res);
      });
    },
    toggleChildren(group) {
      const parentGroup = group;
      if (!parentGroup.isOpen) {
        if (parentGroup.children.length === 0) {
          parentGroup.isChildrenLoading = true;
          this.fetchGroups({
            parentId: parentGroup.id,
          })
            .then(res => {
              this.store.setGroupChildren(parentGroup, res);
            })
            .catch(() => {
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
      const { fullName } = group;
      this.targetGroup = group;
      this.targetParentGroup = parentGroup;
      this.showModal = true;
      this.groupLeaveConfirmationMessage = sprintf(
        s__('GroupsTree|Are you sure you want to leave the "%{fullName}" group?'),
        { fullName },
      );
    },
    hideLeaveGroupModal() {
      this.showModal = false;
    },
    leaveGroup() {
      this.showModal = false;
      this.targetGroup.isBeingRemoved = true;
      this.service
        .leaveGroup(this.targetGroup.leavePath)
        .then(res => {
          $.scrollTo(0);
          this.store.removeGroup(this.targetGroup, this.targetParentGroup);
          Flash(res.data.notice, 'notice');
        })
        .catch(err => {
          let message = COMMON_STR.FAILURE;
          if (err.status === 403) {
            message = COMMON_STR.LEAVE_FORBIDDEN;
          }
          Flash(message);
          this.targetGroup.isBeingRemoved = false;
        });
    },
    showEmptyState() {
      const { containerEl } = this;
      const contentListEl = containerEl.querySelector(CONTENT_LIST_CLASS);
      const emptyStateEl = containerEl.querySelector('.empty-state');

      if (contentListEl) {
        contentListEl.remove();
      }

      if (emptyStateEl) {
        emptyStateEl.classList.remove(HIDDEN_CLASS);
      }
    },
    updatePagination(headers) {
      this.store.setPaginationInfo(headers);
    },
    updateGroups(groups, fromSearch) {
      const hasGroups = groups && groups.length > 0;
      this.isSearchEmpty = !hasGroups;

      if (fromSearch) {
        this.store.setSearchedGroups(groups);
      } else {
        this.store.setGroups(groups);
      }

      if (this.action && !hasGroups && !fromSearch) {
        this.showEmptyState();
      }
    },
  },
};
</script>

<template>
  <div>
    <gl-loading-icon
      v-if="isLoading"
      :label="s__('GroupsTree|Loading groups')"
      size="md"
      class="loading-animation prepend-top-20"
    />
    <groups-component
      v-if="!isLoading"
      :groups="groups"
      :search-empty="isSearchEmpty"
      :search-empty-message="searchEmptyMessage"
      :page-info="pageInfo"
      :action="action"
    />
    <deprecated-modal
      v-show="showModal"
      :primary-button-label="__('Leave')"
      :title="__('Are you sure?')"
      :text="groupLeaveConfirmationMessage"
      kind="warning"
      @cancel="hideLeaveGroupModal"
      @submit="leaveGroup"
    />
  </div>
</template>
