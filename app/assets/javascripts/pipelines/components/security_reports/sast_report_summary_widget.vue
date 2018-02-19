<script>
  import { sprintf, n__, __ } from '~/locale';
  import ciIcon from '~/vue_shared/components/ci_icon.vue';

  export default {
    name: 'SastSummaryReport',
    components: {
      ciIcon,
    },
    props: {
      unresolvedIssues: {
        type: Array,
        required: false,
        default: () => ([]),
      },
      link: {
        type: String,
        required: true,
      },
    },
    computed: {
      summarySastText() {
        if (this.unresolvedIssues.length) {
          return n__(
            sprintf('SAST detected %{link}', {
              link: `<a href=${this.link} class="prepend-left-5">%d security vulnerability</a>`,
            }, false),
            sprintf('SAST detected %{link}', {
              link: `<a href=${this.link} class="prepend-left-5">%d security vulnerabilities</a>`,
            }, false),
            this.unresolvedIssues.length,
          );
        }

        return sprintf(__('SAST detected %{link} '), {
          link: `<a href=${this.link} class="prepend-left-5">no security vulnerabilities</a>`,
        }, false);
      },
      statusIcon() {
        if (this.unresolvedIssues) {
          return {
            group: 'warning',
            icon: 'status_warning',
          };
        }
        return {
          group: 'success',
          icon: 'status_success',
        };
      },
    },
  };
</script>
<template>
  <div class="well-segment flex">
    <ci-icon
      :status="statusIcon"
      class="flex flex-align-self-center"
    />

    <span
      class="prepend-left-10 flex flex-align-self-center"
      v-html="summarySastText"
    >
    </span>
  </div>
</template>
