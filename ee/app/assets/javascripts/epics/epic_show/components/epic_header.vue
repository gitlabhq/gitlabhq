<script>
  import userAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
  import timeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
  import tooltip from '~/vue_shared/directives/tooltip';
  import loadingButton from '~/vue_shared/components/loading_button.vue';
  import { s__ } from '~/locale';
  import eventHub from '../../event_hub';

  export default {
    name: 'EpicHeader',
    directives: {
      tooltip,
    },
    components: {
      userAvatarLink,
      timeagoTooltip,
      loadingButton,
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
      canDelete: {
        type: Boolean,
        required: false,
        default: false,
      },
    },
    data() {
      return {
        deleteLoading: false,
      };
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
    },
  };
</script>

<template>
  <div class="detail-page-header">
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
    <loading-button
      v-if="canDelete"
      :loading="deleteLoading"
      :label="s__('Delete')"
      container-class="btn btn-remove btn-inverted flex-right"
      @click="deleteEpic"
    />
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
