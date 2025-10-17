<script>
import { GlLoadingIcon, GlModal } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { HTTP_STATUS_FORBIDDEN } from '~/lib/utils/http_status';
import { mergeUrlParams, getParameterByName } from '~/lib/utils/url_utility';
import { scrollTo } from '~/lib/utils/scroll_utils';
import { __, s__, sprintf } from '~/locale';

import { COMMON_STR, ACTIVE_TAB_INACTIVE } from '../constants';
import eventHub from '../event_hub';
import GroupsComponent from './groups.vue';

export default {
  components: {
    GroupsComponent,
    GlModal,
    GlLoadingIcon,
  },
  props: {
    action: {
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
  },
  data() {
    return {
      isModalVisible: false,
      isLoading: true,
      fromSearch: false,
      targetGroup: null,
      targetParentGroup: null,
    };
  },
  computed: {
    primaryProps() {
      return {
        text: __('Leave group'),
        attributes: { variant: 'danger', category: 'primary' },
      };
    },
    cancelProps() {
      return {
        text: __('Cancel'),
      };
    },
    groupLeaveConfirmationTitle() {
      if (!this.targetGroup) {
        return '';
      }

      return sprintf(s__('GroupsTree|Are you sure you want to leave "%{fullName}"?'), {
        fullName: this.targetGroup.fullName,
      });
    },
    groups() {
      return this.store.getGroups();
    },
    hasGroups() {
      return this.groups && this.groups.length > 0;
    },
    pageInfo() {
      return this.store.getPaginationInfo();
    },
    filterGroupsBy() {
      return getParameterByName('filter') || null;
    },
  },
  created() {
    eventHub.$on(`${this.action}fetchPage`, this.fetchPage);
    eventHub.$on(`${this.action}toggleChildren`, this.toggleChildren);
    eventHub.$on(`${this.action}showLeaveGroupModal`, this.showLeaveGroupModal);
    eventHub.$on(`${this.action}fetchFilteredAndSortedGroups`, this.fetchFilteredAndSortedGroups);
  },
  mounted() {
    this.fetchAllGroups();
  },
  beforeDestroy() {
    eventHub.$off(`${this.action}fetchPage`, this.fetchPage);
    eventHub.$off(`${this.action}toggleChildren`, this.toggleChildren);
    eventHub.$off(`${this.action}showLeaveGroupModal`, this.showLeaveGroupModal);
    eventHub.$off(`${this.action}fetchFilteredAndSortedGroups`, this.fetchFilteredAndSortedGroups);
  },
  methods: {
    hideModal() {
      this.isModalVisible = false;
    },
    showModal() {
      this.isModalVisible = true;
    },
    fetchGroups({ parentId, page, filterGroupsBy, sortBy, updatePagination }) {
      return this.service
        .getGroups(parentId, page, filterGroupsBy, sortBy)
        .then((res) => {
          if (updatePagination) {
            this.updatePagination(res.headers);
          }
          return res.data;
        })
        .catch(() => {
          this.isLoading = false;
          scrollTo({ top: 0, behavior: 'smooth' }, this.$el);

          createAlert({ message: COMMON_STR.FAILURE });
        });
    },
    fetchAllGroups() {
      const page = getParameterByName('page') || null;
      const sortBy = getParameterByName('sort') || null;

      this.isLoading = true;

      return this.fetchGroups({
        page,
        filterGroupsBy: this.filterGroupsBy,
        sortBy,
        updatePagination: true,
      }).then((res) => {
        this.isLoading = false;
        this.updateGroups(res, Boolean(this.filterGroupsBy));
      });
    },
    fetchFilteredAndSortedGroups({ filterGroupsBy, sortBy }) {
      this.isLoading = true;

      return this.fetchGroups({
        filterGroupsBy,
        sortBy,
        updatePagination: true,
      }).then((res) => {
        this.isLoading = false;
        this.updateGroups(res, Boolean(filterGroupsBy));
      });
    },
    fetchPage({ page, filterGroupsBy, sortBy }) {
      this.isLoading = true;

      return this.fetchGroups({
        page,
        filterGroupsBy,
        sortBy,
        updatePagination: true,
      }).then((res) => {
        this.isLoading = false;
        scrollTo({ top: 0, behavior: 'smooth' }, this.$el);

        const currentPath = mergeUrlParams({ page }, window.location.href);
        window.history.replaceState(
          {
            page: currentPath,
          },
          document.title,
          currentPath,
        );

        this.updateGroups(res, Boolean(filterGroupsBy));
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
            .then((res) => {
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
      this.targetGroup = group;
      this.targetParentGroup = parentGroup;
      this.showModal();
    },
    leaveGroup() {
      this.targetGroup.isBeingRemoved = true;
      this.service
        .leaveGroup(this.targetGroup.leavePath)
        .then((res) => {
          scrollTo({ top: 0, behavior: 'smooth' }, this.$el);
          this.store.removeGroup(this.targetGroup, this.targetParentGroup);
          this.$toast.show(res.data.notice);
        })
        .catch((err) => {
          let message = COMMON_STR.FAILURE;
          if (err.status === HTTP_STATUS_FORBIDDEN) {
            message = COMMON_STR.LEAVE_FORBIDDEN;
          }
          createAlert({ message });
          this.targetGroup.isBeingRemoved = false;
        });
    },
    updatePagination(headers) {
      this.store.setPaginationInfo(headers);
    },
    updateGroups(groups, fromSearch) {
      this.fromSearch = fromSearch;

      const isOpenOverride = this.action === ACTIVE_TAB_INACTIVE ? false : undefined;

      this.store.setGroups(groups, isOpenOverride);
    },
  },
};
</script>

<template>
  <div>
    <gl-loading-icon
      v-if="isLoading"
      :label="s__('GroupsTree|Loading groups')"
      size="lg"
      class="loading-animation gl-mt-5"
    />
    <template v-else>
      <groups-component v-if="hasGroups" :groups="groups" :page-info="pageInfo" :action="action" />
      <slot v-else name="empty-state"></slot>
    </template>
    <gl-modal
      modal-id="leave-group-modal"
      :visible="isModalVisible"
      :title="groupLeaveConfirmationTitle"
      :action-primary="primaryProps"
      :action-cancel="cancelProps"
      @primary="leaveGroup"
      @hide="hideModal"
    >
      <p>{{ s__('GroupsTree|When you leave this group:') }}</p>
      <ul>
        <li>{{ s__('GroupsTree|You lose access to all projects within this group') }}</li>
        <li>
          {{
            s__(
              'GroupsTree|Your assigned issues and merge requests remain, but you cannot view or modify them',
            )
          }}
        </li>
        <li>{{ s__('GroupsTree|You need an invitation to rejoin') }}</li>
      </ul>
    </gl-modal>
  </div>
</template>
