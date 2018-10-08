<script>
  import $ from 'jquery';
  import userAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
  import timeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
  import Icon from '~/vue_shared/components/icon.vue';
  import LoadingButton from '~/vue_shared/components/loading_button.vue';
  import tooltip from '~/vue_shared/directives/tooltip';
  import { __, s__ } from '~/locale';
  import eventHub from '../../event_hub';
  import { stateEvent } from '../../constants';

  export default {
    name: 'EpicHeader',
    directives: {
      tooltip,
    },
    components: {
      Icon,
      LoadingButton,
      userAvatarLink,
      timeagoTooltip,
    },
    props: {
      author: {
        type: Object,
        required: true,
        validator: value => value.url && value.username && value.name,
      },
      created: {
        type: String,
        required: true,
      },
      open: {
        type: Boolean,
        required: true,
      },
      canUpdate: {
        required: true,
        type: Boolean,
      },
    },
    data() {
      return {
        deleteLoading: false,
        statusUpdating: false,
        isEpicOpen: this.open,
      };
    },
    computed: {
      statusIcon() {
        return this.isEpicOpen ? 'issue-open-m' : 'mobile-issue-close';
      },
      statusText() {
        return this.isEpicOpen ? __('Open') : __('Closed');
      },
      actionButtonClass() {
        return `btn btn-grouped js-btn-epic-action qa-close-reopen-epic-button ${this.isEpicOpen ? 'btn-close' : 'btn-open'}`;
      },
      actionButtonText() {
        return this.isEpicOpen ? __('Close epic') : __('Reopen epic');
      },
    },
    mounted() {
      $(document).on('issuable_vue_app:change', (e, isClosed) => {
        this.isEpicOpen = e.detail ? !e.detail.isClosed : !isClosed;
        this.statusUpdating = false;
      });
    },
    methods: {
      deleteEpic() {
        if (window.confirm(s__('Epic will be removed! Are you sure?'))) { // eslint-disable-line no-alert
          this.deleteLoading = true;
          this.$emit('deleteEpic');
        }
      },
      toggleSidebar() {
        eventHub.$emit('toggleSidebar');
      },
      toggleStatus() {
        this.statusUpdating = true;
        this.$emit('toggleEpicStatus', this.isEpicOpen ? stateEvent.close : stateEvent.reopen);
      },
    },
  };
</script>

<template>
  <div class="detail-page-header">
    <div class="detail-page-header-body">
      <div
        :class="{ 'status-box-open': isEpicOpen, 'status-box-issue-closed': !isEpicOpen }"
        class="issuable-status-box status-box"
      >
        <icon
          :name="statusIcon"
          css-classes="d-block d-sm-none"
        />
        <span class="d-none d-sm-block">{{ statusText }}</span>
      </div>
      <div class="issuable-meta">
        {{ s__('Opened') }}
        <timeago-tooltip :time="created" />
        {{ s__('by') }}
        <strong>
          <user-avatar-link
            :link-href="author.url"
            :img-src="author.src"
            :img-size="24"
            :tooltip-text="author.username"
            :username="author.name"
            img-css-classes="avatar-inline"
          />
        </strong>
      </div>
    </div>
    <div
      v-if="canUpdate"
      class="detail-page-header-actions js-issuable-actions"
    >
      <loading-button
        :label="actionButtonText"
        :loading="statusUpdating"
        :container-class="actionButtonClass"
        @click="toggleStatus"
      />
    </div>
    <button
      :aria-label="__('toggle collapse')"
      class="btn btn-default float-right d-block d-sm-none
gutter-toggle issuable-gutter-toggle js-sidebar-toggle"
      type="button"
      @click="toggleSidebar"
    >
      <i class="fa fa-angle-double-left"></i>
    </button>
  </div>
</template>
