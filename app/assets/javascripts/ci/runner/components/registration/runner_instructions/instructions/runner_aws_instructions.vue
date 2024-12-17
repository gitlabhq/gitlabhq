<script>
import {
  GlButton,
  GlSprintf,
  GlIcon,
  GlLink,
  GlFormRadioGroup,
  GlFormRadio,
  GlAccordion,
  GlAccordionItem,
} from '@gitlab/ui';
import Tracking from '~/tracking';
import { getBaseURL, objectToQuery, visitUrl } from '~/lib/utils/url_utility';
import { __, s__ } from '~/locale';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';
import {
  AWS_README_URL,
  AWS_CF_BASE_URL,
  AWS_TEMPLATES_BASE_URL,
  AWS_EASY_BUTTONS,
} from '../constants';

export default {
  components: {
    GlButton,
    GlSprintf,
    GlIcon,
    GlLink,
    GlFormRadioGroup,
    GlFormRadio,
    GlAccordion,
    GlAccordionItem,
    ModalCopyButton,
  },
  mixins: [Tracking.mixin()],
  props: {
    registrationToken: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      selectedIndex: 0,
    };
  },
  computed: {
    selected() {
      return this.$options.easyButtons[this.selectedIndex];
    },
  },
  methods: {
    borderBottom(idx) {
      return idx < this.$options.easyButtons.length - 1;
    },
    easyButtonUrl(easyButton) {
      const params = {
        templateURL: AWS_TEMPLATES_BASE_URL + easyButton.templateName,
        stackName: easyButton.stackName,
        param_3GITLABRunnerInstanceURL: getBaseURL(),
      };
      return AWS_CF_BASE_URL + objectToQuery(params);
    },
    trackCiRunnerTemplatesClick(stackName) {
      this.track('template_clicked', {
        label: stackName,
      });
    },
    onOk() {
      this.trackCiRunnerTemplatesClick(this.selected.stackName);
      visitUrl(this.easyButtonUrl(this.selected), true);
    },
    onClose() {
      this.$emit('close');
    },
  },
  i18n: {
    instructions: s__(
      'Runners|Select your preferred runner, then choose the capacity for the runner in the AWS CloudFormation console.',
    ),
    chooseRunner: s__('Runners|Choose your preferred GitLab Runner'),
    dontSeeWhatYouAreLookingFor: s__(
      "Runners|Don't see what you are looking for? See the full list of options, including a fully customizable option %{linkStart}here%{linkEnd}.",
    ),
    runnerRegistrationToken: s__('Runners|Runner Registration token'),
    copyInstructions: s__('Runners|Copy registration token'),
    moreDetails: __('More Details'),
    lessDetails: __('Less Details'),
    close: __('Close'),
    deployRunnerInAws: s__('Runners|Deploy GitLab Runner in AWS'),
    externalLink: __('(external link)'),
  },
  readmeUrl: AWS_README_URL,
  easyButtons: AWS_EASY_BUTTONS,
};
</script>
<template>
  <div>
    <p>{{ $options.i18n.instructions }}</p>

    <gl-form-radio-group v-model="selectedIndex" :label="$options.i18n.chooseRunner" label-sr-only>
      <gl-form-radio
        v-for="(easyButton, idx) in $options.easyButtons"
        :key="easyButton.templateName"
        :value="idx"
        class="gl-py-5 gl-pl-8"
        :class="{ 'gl-border-b': borderBottom(idx) }"
      >
        <div class="-gl-mt-1 gl-pb-2 gl-pl-4 gl-font-bold">
          {{ easyButton.description }}
          <gl-accordion :header-level="3" class="gl-pt-3">
            <gl-accordion-item
              :title="$options.i18n.moreDetails"
              :title-visible="$options.i18n.lessDetails"
              class="gl-font-normal"
            >
              <p class="gl-pt-2">{{ easyButton.moreDetails1 }}</p>
              <p class="gl-m-0">{{ easyButton.moreDetails2 }}</p>
            </gl-accordion-item>
          </gl-accordion>
        </div>
      </gl-form-radio>
    </gl-form-radio-group>
    <p>
      <gl-sprintf :message="$options.i18n.dontSeeWhatYouAreLookingFor">
        <template #link="{ content }">
          <gl-link :href="$options.readmeUrl" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </p>
    <template v-if="registrationToken">
      <h5 class="gl-mb-3">{{ $options.i18n.runnerRegistrationToken }}</h5>
      <div class="gl-flex">
        <pre class="gl-bg-gray gl-grow gl-whitespace-pre-line">{{ registrationToken }}</pre>
        <modal-copy-button
          :title="$options.i18n.copyInstructions"
          :text="registrationToken"
          css-classes="gl-self-start gl-ml-2 gl-mt-2"
          category="tertiary"
        />
      </div>
    </template>
    <footer class="gl-flex gl-justify-end gl-gap-3 gl-pt-3">
      <gl-button data-testid="close-btn" @click="onClose()">{{ $options.i18n.close }}</gl-button>
      <gl-button variant="confirm" @click="onOk()">
        {{ $options.i18n.deployRunnerInAws }}
        <gl-icon name="external-link" :aria-label="$options.i18n.externalLink" />
      </gl-button>
    </footer>
  </div>
</template>
