<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { captureException } from '~/sentry/sentry_browser_wrapper';
import PipelineWizard from '~/pipeline_wizard/pipeline_wizard.vue';
import PagesWizardTemplate from '~/pipeline_wizard/templates/pages.yml?raw';
import { logError } from '~/lib/logger';
import { s__ } from '~/locale';
import { visitUrl } from '~/lib/utils/url_utility';
import pagesMarkOnboardingComplete from '../queries/mark_onboarding_complete.graphql';

export const i18n = {
  loadingMessage: s__('GitLabPages|Updating your Pages configuration...'),
};

export default {
  name: 'PagesPipelineWizard',
  i18n,
  PagesWizardTemplate,
  components: {
    PipelineWizard,
    GlLoadingIcon,
  },
  props: {
    projectPath: {
      type: String,
      required: true,
    },
    defaultBranch: {
      type: String,
      required: true,
    },
    redirectToWhenDone: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      loading: false,
    };
  },
  methods: {
    async updateOnboardingState() {
      try {
        await this.$apollo.mutate({
          mutation: pagesMarkOnboardingComplete,
          variables: {
            input: { projectPath: this.projectPath },
          },
        });
      } catch (e) {
        // eslint-disable-next-line @gitlab/require-i18n-strings
        logError('Updating the pages onboarding state failed', e);
        captureException(e);
      }
    },
    async onDone() {
      this.loading = true;
      await this.updateOnboardingState();
      visitUrl(this.redirectToWhenDone);
    },
  },
};
</script>

<template>
  <div>
    <div
      v-if="loading"
      class="gl-rounded-base gl-p-3 gl-text-center"
      data-testid="onboarding-mutation-loading"
    >
      <gl-loading-icon />
      {{ $options.i18n.loadingMessage }}
    </div>
    <pipeline-wizard
      v-else
      :template="$options.PagesWizardTemplate"
      :project-path="projectPath"
      :default-branch="defaultBranch"
      @done="onDone"
    />
  </div>
</template>
