<script>
import { GlModal, GlSprintf, GlLink } from '@gitlab/ui';
import ExperimentTracking from '~/experimentation/experiment_tracking';
import { getBaseURL, objectToQuery } from '~/lib/utils/url_utility';
import { __, s__ } from '~/locale';
import {
  EXPERIMENT_NAME,
  README_URL,
  CF_BASE_URL,
  TEMPLATES_BASE_URL,
  EASY_BUTTONS,
} from './constants';

export default {
  components: {
    GlModal,
    GlSprintf,
    GlLink,
  },
  props: {
    modalId: {
      type: String,
      required: true,
    },
  },
  methods: {
    easyButtonUrl(easyButton) {
      const params = {
        templateURL: TEMPLATES_BASE_URL + easyButton.templateName,
        stackName: easyButton.stackName,
        param_3GITLABRunnerInstanceURL: getBaseURL(),
      };
      return CF_BASE_URL + objectToQuery(params);
    },
    trackCiRunnerTemplatesClick(stackName) {
      const tracking = new ExperimentTracking(EXPERIMENT_NAME);
      tracking.event(`template_clicked_${stackName}`);
    },
  },
  i18n: {
    title: s__('Runners|Deploy GitLab Runner in AWS'),
    instructions: s__(
      'Runners|For each solution, you will choose a capacity. 1 enables warm HA through Auto Scaling group re-spawn. 2 enables hot HA because the service is available even when a node is lost. 3 or more enables hot HA and manual scaling of runner fleet.',
    ),
    dont_see_what_you_are_looking_for: s__(
      "Rnners|Don't see what you are looking for? See the full list of options, including a fully customizable option, %{linkStart}here%{linkEnd}.",
    ),
    note: s__(
      'Runners|If you do not select an AWS VPC, the runner will deploy to the Default VPC in the AWS Region you select. Please consult with your AWS administrator to understand if there are any security risks to deploying into the Default VPC in any given region in your AWS account.',
    ),
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
    :action-secondary="$options.closeButton"
    size="sm"
  >
    <p>{{ $options.i18n.instructions }}</p>
    <ul class="gl-list-style-none gl-p-0 gl-mb-0">
      <li v-for="easyButton in $options.easyButtons" :key="easyButton.templateName">
        <gl-link
          :href="easyButtonUrl(easyButton)"
          target="_blank"
          class="gl-display-flex gl-font-weight-bold"
          @click="trackCiRunnerTemplatesClick(easyButton.stackName)"
        >
          <img
            :title="easyButton.stackName"
            :alt="easyButton.stackName"
            src="/assets/aws-cloud-formation.png"
            width="46"
            height="46"
            class="gl-mt-2 gl-mr-5 gl-mb-6"
          />
          {{ easyButton.description }}
        </gl-link>
      </li>
    </ul>
    <p>
      <gl-sprintf :message="$options.i18n.dont_see_what_you_are_looking_for">
        <template #link="{ content }">
          <gl-link :href="$options.readmeUrl" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </p>
    <p class="gl-font-sm gl-mb-0">{{ $options.i18n.note }}</p>
  </gl-modal>
</template>
