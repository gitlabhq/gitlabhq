<script>
import { GlButton, GlCard, GlSprintf, GlLink, GlPopover, GlModalDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import RunnerInstructionsModal from '~/vue_shared/components/runner_instructions/runner_instructions_modal.vue';
import apolloProvider from '~/pipelines/graphql/provider';
import CiTemplates from './ci_templates.vue';

export default {
  components: {
    GlButton,
    GlCard,
    GlSprintf,
    GlLink,
    GlPopover,
    RunnerInstructionsModal,
    CiTemplates,
  },
  directives: {
    GlModalDirective,
  },
  inject: ['pipelineEditorPath', 'iosRunnersAvailable'],
  props: {
    registrationToken: {
      type: String,
      required: false,
      default: null,
    },
  },
  apolloProvider,
  iOSTemplateName: 'iOS-Fastlane',
  modalId: 'runner-instructions-modal',
  runnerDocsLink: 'https://docs.gitlab.com/runner/install/osx',
  whatElseLink: helpPagePath('ci/index.md'),
  i18n: {
    title: s__('Pipelines|Get started with GitLab CI/CD'),
    subtitle: s__('Pipelines|Building for iOS?'),
    explanation: s__("Pipelines|We'll walk you through how to deploy to iOS in two easy steps."),
    runnerSetupTitle: s__('Pipelines|1. Set up a runner'),
    runnerSetupButton: s__('Pipelines|Set up a runner'),
    runnerSetupBodyUnfinished: s__(
      'Pipelines|GitLab Runner is an application that works with GitLab CI/CD to run jobs in a pipeline.',
    ),
    runnerSetupBodyFinished: s__(
      'Pipelines|You have runners available to run your job now. No need to do anything else.',
    ),
    runnerSetupPopoverTitle: s__(
      "Pipelines|Let's get that runner set up! %{emojiStart}tada%{emojiEnd}",
    ),
    runnerSetupPopoverBodyLine1: s__(
      'Pipelines|Follow these instructions to install GitLab Runner on macOS.',
    ),
    runnerSetupPopoverBodyLine2: s__(
      'Pipelines|Need more information to set up your runner? %{linkStart}Check out our documentation%{linkEnd}.',
    ),
    configurePipelineTitle: s__('Pipelines|2. Configure deployment pipeline'),
    configurePipelineBody: s__("Pipelines|We'll guide you through a simple pipeline set-up."),
    configurePipelineButton: s__('Pipelines|Configure pipeline'),
    noWalkthroughTitle: s__("Pipelines|Don't need a guide? Jump in right away with a template."),
    noWalkthroughExplanation: s__('Pipelines|Based on your project, we recommend this template:'),
    notBuildingForIos: s__(
      "Pipelines|Not building for iOS or not what you're looking for? %{linkStart}See what else%{linkEnd} GitLab CI/CD has to offer.",
    ),
  },
  data() {
    return {
      isModalShown: false,
      isPopoverShown: false,
      isRunnerSetupFinished: this.iosRunnersAvailable,
      popoverTarget: `${this.$options.modalId}___BV_modal_content_`,
      configurePipelineLink: mergeUrlParams(
        { template: this.$options.iOSTemplateName },
        this.pipelineEditorPath,
      ),
    };
  },
  computed: {
    runnerSetupBodyText() {
      return this.iosRunnersAvailable
        ? this.$options.i18n.runnerSetupBodyFinished
        : this.$options.i18n.runnerSetupBodyUnfinished;
    },
  },
  methods: {
    showModal() {
      this.isModalShown = true;
    },
    hideModal() {
      this.togglePopover();
      this.isRunnerSetupFinished = true;
    },
    togglePopover() {
      this.isPopoverShown = !this.isPopoverShown;
    },
  },
};
</script>

<template>
  <div>
    <h2 class="gl-font-size-h2 gl-text-gray-900">{{ $options.i18n.title }}</h2>
    <h3 class="gl-font-lg gl-text-gray-900 gl-mt-1">{{ $options.i18n.subtitle }}</h3>
    <p>{{ $options.i18n.explanation }}</p>

    <div class="gl-lg-display-flex">
      <div class="gl-lg-display-flex gl-lg-w-25p gl-lg-pr-4 gl-mb-4">
        <gl-card body-class="gl-display-flex gl-flex-grow-1">
          <div
            class="gl-display-flex gl-flex-grow-1 gl-flex-direction-column gl-justify-content-space-between gl-align-items-flex-start"
          >
            <div>
              <div class="gl-py-5">
                <gl-emoji
                  v-show="isRunnerSetupFinished"
                  class="gl-font-size-h2-xl"
                  data-name="white_check_mark"
                  data-testid="runner-setup-marked-completed"
                />
                <gl-emoji
                  v-show="!isRunnerSetupFinished"
                  class="gl-font-size-h2-xl"
                  data-name="tools"
                  data-testid="runner-setup-marked-todo"
                />
              </div>
              <span class="gl-text-gray-800 gl-font-weight-bold">
                {{ $options.i18n.runnerSetupTitle }}
              </span>
              <p class="gl-font-sm gl-mt-3">{{ runnerSetupBodyText }}</p>
            </div>

            <gl-button
              v-if="!iosRunnersAvailable"
              v-gl-modal-directive="$options.modalId"
              category="primary"
              variant="confirm"
              @click="showModal"
            >
              {{ $options.i18n.runnerSetupButton }}
            </gl-button>
            <runner-instructions-modal
              v-if="isModalShown"
              :modal-id="$options.modalId"
              :registration-token="registrationToken"
              default-platform-name="osx"
              @shown="togglePopover"
              @hide="hideModal"
            />
            <gl-popover
              v-if="isPopoverShown"
              :show="true"
              :show-close-button="true"
              :target="popoverTarget"
              triggers="manual"
              placement="left"
              fallback-placement="clockwise"
            >
              <template #title>
                <gl-sprintf :message="$options.i18n.runnerSetupPopoverTitle">
                  <template #emoji="{ content }">
                    <gl-emoji class="gl-ml-2" :data-name="content" />
                  </template>
                </gl-sprintf>
              </template>
              <div class="gl-mb-5">
                {{ $options.i18n.runnerSetupPopoverBodyLine1 }}
              </div>
              <gl-sprintf :message="$options.i18n.runnerSetupPopoverBodyLine2">
                <template #link="{ content }">
                  <gl-link :href="$options.runnerDocsLink" target="_blank">{{ content }}</gl-link>
                </template>
              </gl-sprintf>
            </gl-popover>
          </div>
        </gl-card>
      </div>
      <div class="gl-lg-display-flex gl-lg-w-25p gl-lg-pr-4 gl-mb-4">
        <gl-card body-class="gl-display-flex gl-flex-grow-1">
          <div
            class="gl-display-flex gl-flex-grow-1 gl-flex-direction-column gl-justify-content-space-between gl-align-items-flex-start"
          >
            <div>
              <div class="gl-py-5"><gl-emoji class="gl-font-size-h2-xl" data-name="tools" /></div>
              <span class="gl-text-gray-800 gl-font-weight-bold">
                {{ $options.i18n.configurePipelineTitle }}
              </span>
              <p class="gl-font-sm gl-mt-3">{{ $options.i18n.configurePipelineBody }}</p>
            </div>

            <gl-button
              :disabled="!isRunnerSetupFinished"
              category="primary"
              variant="confirm"
              data-testid="configure-pipeline-link"
              :href="configurePipelineLink"
            >
              {{ $options.i18n.configurePipelineButton }}
            </gl-button>
          </div>
        </gl-card>
      </div>
    </div>
    <h3 class="gl-font-lg gl-text-gray-900 gl-mt-5">{{ $options.i18n.noWalkthroughTitle }}</h3>
    <p>{{ $options.i18n.noWalkthroughExplanation }}</p>
    <ci-templates
      :filter-templates="/* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */ [
        $options.iOSTemplateName,
      ] /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */"
      :disabled="!isRunnerSetupFinished"
    />
    <p>
      <gl-sprintf :message="$options.i18n.notBuildingForIos">
        <template #link="{ content }">
          <gl-link :href="$options.whatElseLink">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </p>
  </div>
</template>
