<script>
  import userAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
  import timeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
  import tooltip from '~/vue_shared/directives/tooltip';

  export default {
    name: 'epicHeader',
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
    },
    directives: {
      tooltip,
    },
    components: {
      userAvatarLink,
      timeagoTooltip,
    },
  };
</script>

<template>
  <div class="detail-page-header">
    <div class="issuable-meta">
      Opened
      <timeagoTooltip
        :time="created"
      />
      by
      <strong>
        <user-avatar-link
          :link-href="author.url"
          :img-src="author.src"
          :img-size="24"
          :tooltipText="author.username"
          :username="author.name"
          imgCssClasses="avatar-inline"
        />
      </strong>
    </div>
  </div>
</template>
