<script>
import { GlButton, GlFormCheckbox, GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';
import {
  PREREQUISITES_DOC_LINK,
  OAUTH_SELF_MANAGED_DOC_LINK,
  SET_UP_INSTANCE_DOC_LINK,
  JIRA_USER_REQUIREMENTS_DOC_LINK,
} from '~/jira_connect/subscriptions/constants';

export default {
  components: {
    GlButton,
    GlFormCheckbox,
    GlLink,
  },
  data() {
    return {
      requiredSteps: [
        {
          name: s__('JiraConnect|Prerequisites'),
          link: PREREQUISITES_DOC_LINK,
          checked: false,
        },
        {
          name: s__('JiraConnect|Set up OAuth authentication'),
          link: OAUTH_SELF_MANAGED_DOC_LINK,
          checked: false,
        },
        {
          name: s__('JiraConnect|Set up your instance'),
          link: SET_UP_INSTANCE_DOC_LINK,
          checked: false,
        },
        {
          name: s__('JiraConnect|Jira user requirements'),
          link: JIRA_USER_REQUIREMENTS_DOC_LINK,
          checked: false,
        },
      ],
    };
  },
  computed: {
    nextDisabled() {
      return !this.requiredSteps.every((step) => step.checked);
    },
  },
};
</script>

<template>
  <div class="gl-mt-5">
    <h3>{{ s__('JiraConnect|Continue setup in GitLab') }}</h3>
    <p>
      {{ s__('JiraConnect|To complete the setup, you must follow a few steps in GitLab:') }}
    </p>
    <div class="gl-mb-5">
      <div v-for="step in requiredSteps" :key="step.name" class="gl-mb-2">
        <gl-form-checkbox v-model="step.checked">
          <gl-link :href="step.link" target="_blank">
            {{ step.name }}
          </gl-link>
        </gl-form-checkbox>
      </div>
    </div>

    <div class="gl-flex gl-justify-between">
      <gl-button @click="$emit('back')">{{ __('Back') }}</gl-button>
      <gl-button variant="confirm" :disabled="nextDisabled" @click="$emit('next')"
        >{{ __('Next') }}
      </gl-button>
    </div>
  </div>
</template>
