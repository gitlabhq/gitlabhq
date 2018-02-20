<script>
  import { sprintf, s__ } from '~/locale';
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
        let text;
        let link;

        if (this.unresolvedIssues.length) {
          text = s__('ciReport|SAST degraded on %{link}');
          link = this.unresolvedIssues.length > 1 ?
            this.getLink(sprintf(
              s__('ciReport|%{d} security vulnerabilities'),
              { d: this.unresolvedIssues.length },
              true,
            )) :
            this.getLink(s__('ciReport|1 security vulnerability'));
        } else {
          text = s__('ciReport|SAST detected %{link}');
          link = this.getLink(s__('ciReport|no security vulnerabilities'));
        }

        return sprintf(text, { link }, false);
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
    methods: {
      getLink(text) {
        return `<a href="${this.link}" class="prepend-left-5">${text}</a>`;
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
