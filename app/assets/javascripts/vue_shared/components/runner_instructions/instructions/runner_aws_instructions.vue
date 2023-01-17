<script>
import {
  GlButton,
  GlSprintf,
  GlLink,
  GlFormRadioGroup,
  GlFormRadio,
  GlAccordion,
  GlAccordionItem,
} from '@gitlab/ui';
import Tracking from '~/tracking';
import { getBaseURL, objectToQuery, visitUrl } from '~/lib/utils/url_utility';
import { __, s__ } from '~/locale';
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
    GlLink,
    GlFormRadioGroup,
    GlFormRadio,
    GlAccordion,
    GlAccordionItem,
  },
  mixins: [Tracking.mixin()],
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
    title: s__('Runners|Deploy GitLab Runner in AWS'),
    instructions: s__(
      'Runners|Select your preferred option here. In the next step, you can choose the capacity for your runner in the AWS CloudFormation console.',
    ),
    chooseRunner: s__('Runners|Choose your preferred GitLab Runner'),
    dontSeeWhatYouAreLookingFor: s__(
      "Runners|Don't see what you are looking for? See the full list of options, including a fully customizable option %{linkStart}here%{linkEnd}.",
    ),
    moreDetails: __('More Details'),
    lessDetails: __('Less Details'),
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
        <div class="gl-mt-n1 gl-pl-4 gl-pb-2 gl-font-weight-bold">
          {{ easyButton.description }}
          <gl-accordion :header-level="3" class="gl-pt-3">
            <gl-accordion-item
              :title="$options.i18n.moreDetails"
              :title-visible="$options.i18n.lessDetails"
              class="gl-font-weight-normal"
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
    <footer class="gl-display-flex gl-justify-content-end gl-pt-3 gl-gap-3">
      <gl-button @click="onClose()">{{ __('Close') }}</gl-button>
      <gl-button variant="confirm" @click="onOk()">
        {{ s__('Runners|Deploy GitLab Runner in AWS') }}
      </gl-button>
    </footer>
  </div>
</template>
