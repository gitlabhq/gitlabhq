<script>
import {
  GlModal,
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
import { README_URL, CF_BASE_URL, TEMPLATES_BASE_URL, EASY_BUTTONS } from './constants';

export default {
  components: {
    GlModal,
    GlSprintf,
    GlLink,
    GlFormRadioGroup,
    GlFormRadio,
    GlAccordion,
    GlAccordionItem,
  },
  mixins: [Tracking.mixin()],
  props: {
    modalId: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      selected: this.$options.easyButtons[0],
    };
  },
  methods: {
    borderBottom(idx) {
      return idx < this.$options.easyButtons.length - 1;
    },
    easyButtonUrl(easyButton) {
      const params = {
        templateURL: TEMPLATES_BASE_URL + easyButton.templateName,
        stackName: easyButton.stackName,
        param_3GITLABRunnerInstanceURL: getBaseURL(),
      };
      return CF_BASE_URL + objectToQuery(params);
    },
    trackCiRunnerTemplatesClick(stackName) {
      this.track('template_clicked', {
        label: stackName,
      });
    },
    handleModalPrimary() {
      this.trackCiRunnerTemplatesClick(this.selected.stackName);
      visitUrl(this.easyButtonUrl(this.selected), true);
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
  deployButton: {
    text: s__('Runners|Deploy GitLab Runner in AWS'),
    attributes: [{ variant: 'confirm' }],
  },
  closeButton: {
    text: __('Cancel'),
    attributes: [{ variant: 'default' }],
  },
  readmeUrl: README_URL,
  easyButtons: EASY_BUTTONS,
};
</script>
<template>
  <gl-modal
    :modal-id="modalId"
    :title="$options.i18n.title"
    :action-primary="$options.deployButton"
    :action-secondary="$options.closeButton"
    size="sm"
    @primary="handleModalPrimary"
  >
    <p>{{ $options.i18n.instructions }}</p>
    <gl-form-radio-group v-model="selected" :label="$options.i18n.chooseRunner" label-sr-only>
      <gl-form-radio
        v-for="(easyButton, idx) in $options.easyButtons"
        :key="easyButton.templateName"
        :value="easyButton"
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
  </gl-modal>
</template>
