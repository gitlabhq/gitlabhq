<script>
  import userAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
  import timeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
  import tooltip from '~/vue_shared/directives/tooltip';
  import loadingButton from '~/vue_shared/components/loading_button.vue';
  import { s__ } from '~/locale';

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
        if (confirm(s__('Epic will be removed! Are you sure?'))) { // eslint-disable-line no-alert
          this.deleteLoading = true;
          this.$emit('deleteEpic');
        }
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
      @click="deleteEpic"
      :label="s__('Delete')"
      container-class="btn btn-remove btn-inverted flex-right"
    />
  </div>
</template>
