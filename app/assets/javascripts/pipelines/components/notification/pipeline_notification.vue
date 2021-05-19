<script>
import { GlBanner, GlLink, GlSprintf } from '@gitlab/ui';
import createFlash from '~/flash';
import { __ } from '~/locale';
import DismissPipelineGraphCallout from '../../graphql/mutations/dismiss_pipeline_notification.graphql';
import getUserCallouts from '../../graphql/queries/get_user_callouts.query.graphql';

const featureName = 'pipeline_needs_banner';
const enumFeatureName = featureName.toUpperCase();

export default {
  i18n: {
    title: __('View job dependencies in the pipeline graph!'),
    description: __(
      'You can now group jobs in the pipeline graph based on which jobs are configured to run first, if you use the %{codeStart}needs:%{codeEnd} keyword to establish job dependencies in your CI/CD pipelines. %{linkStart}Learn how to speed up your pipeline with needs.%{linkEnd}',
    ),
    buttonText: __('Provide feedback'),
  },
  components: {
    GlBanner,
    GlLink,
    GlSprintf,
  },
  apollo: {
    callouts: {
      query: getUserCallouts,
      update(data) {
        return data?.currentUser?.callouts?.nodes.map((c) => c.featureName);
      },
      error() {
        this.hasError = true;
      },
    },
  },
  inject: ['dagDocPath'],
  data() {
    return {
      callouts: [],
      dismissedAlert: false,
      hasError: false,
    };
  },
  computed: {
    showBanner() {
      return (
        !this.$apollo.queries.callouts?.loading &&
        !this.hasError &&
        !this.dismissedAlert &&
        !this.callouts.includes(enumFeatureName)
      );
    },
  },
  methods: {
    handleClose() {
      this.dismissedAlert = true;
      try {
        this.$apollo.mutate({
          mutation: DismissPipelineGraphCallout,
          variables: {
            featureName,
          },
        });
      } catch {
        createFlash(__('There was a problem dismissing this notification.'));
      }
    },
  },
};
</script>
<template>
  <gl-banner
    v-if="showBanner"
    :title="$options.i18n.title"
    :button-text="$options.i18n.buttonText"
    button-link="https://gitlab.com/gitlab-org/gitlab/-/issues/327688"
    variant="introduction"
    @close="handleClose"
  >
    <p>
      <gl-sprintf :message="$options.i18n.description">
        <template #link="{ content }">
          <gl-link :href="dagDocPath" target="_blank"> {{ content }}</gl-link>
        </template>
        <template #code="{ content }">
          <code>{{ content }}</code>
        </template>
      </gl-sprintf>
    </p>
  </gl-banner>
</template>
