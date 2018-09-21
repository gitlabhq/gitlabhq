<script>
  import _ from 'underscore';
  import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

  export default {
    components: {
      TimeagoTooltip,
    },
    props: {
      erasedByUser: {
        type: Boolean,
        required: true,
      },
      user: {
        type: Object,
        required: false,
        default: () => ({}),
      },
      erasedAt: {
        type: String,
        required: true,
      },
    },
    computed: {
      erasedByUser() {
        return _.isEmpty(this.user);
      },
    },
  };
</script>
<template>
  <div class="prepend-top-default js-build-erased">
    <div class="erased alert alert-warning">
      <template v-if="erasedByUser">
        {{ s__("Job|Job has been erased by") }}
        <a :href="user.web_url">
          {{ user.username }}
        </a>
      </template>
      <template v-else>
        {{ s__("Job|Job has been erased") }}
      </template>

      <timeago-tooltip
        :time="erasedAt"
      />
    </div>
  </div>
</template>
