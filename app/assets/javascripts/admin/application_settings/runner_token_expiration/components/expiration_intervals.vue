<script>
import { GlFormGroup } from '@gitlab/ui';
import { s__ } from '~/locale';
import ChronicDurationInput from '~/admin/application_settings/runner_token_expiration/components/chronic_duration_input.vue';
import ExpirationIntervalDescription from './expiration_interval_description.vue';

export default {
  components: {
    ChronicDurationInput,
    ExpirationIntervalDescription,
    GlFormGroup,
  },
  props: {
    instanceRunnerExpirationInterval: {
      type: Number,
      required: false,
      default: null,
    },
    groupRunnerExpirationInterval: {
      type: Number,
      required: false,
      default: null,
    },
    projectRunnerExpirationInterval: {
      type: Number,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      perInput: {
        instance: {
          value: this.instanceRunnerExpirationInterval,
          valid: null,
          feedback: '',
        },
        group: {
          value: this.groupRunnerExpirationInterval,
          valid: null,
          feedback: '',
        },
        project: {
          value: this.projectRunnerExpirationInterval,
          valid: null,
          feedback: '',
        },
      },
    };
  },
  methods: {
    updateValidity(obj, event) {
      /* eslint-disable no-param-reassign */
      obj.valid = event.valid;
      obj.feedback = event.feedback;
      /* eslint-enable no-param-reassign */
    },
  },
  i18n: {
    instanceRunnerTitle: s__('AdminSettings|Instance runners expiration'),
    instanceRunnerDescription: s__(
      'AdminSettings|Set the expiration time of authentication tokens of newly registered instance runners. Authentication tokens are automatically reset at these intervals.',
    ),
    groupRunnerTitle: s__('AdminSettings|Group runners expiration'),
    groupRunnerDescription: s__(
      'AdminSettings|Set the expiration time of authentication tokens of newly registered group runners.',
    ),
    projectRunnerTitle: s__('AdminSettings|Project runners expiration'),
    projectRunnerDescription: s__(
      'AdminSettings|Set the expiration time of authentication tokens of newly registered project runners.',
    ),
  },
};
</script>
<template>
  <div>
    <gl-form-group
      :label="$options.i18n.instanceRunnerTitle"
      :invalid-feedback="perInput.instance.feedback"
      :state="perInput.instance.valid"
    >
      <template #description>
        <expiration-interval-description :message="$options.i18n.instanceRunnerDescription" />
      </template>
      <chronic-duration-input
        v-model="perInput.instance.value"
        name="application_setting[runner_token_expiration_interval]"
        :state="perInput.instance.valid"
        @valid="updateValidity(perInput.instance, $event)"
      />
    </gl-form-group>
    <gl-form-group
      :label="$options.i18n.groupRunnerTitle"
      :invalid-feedback="perInput.group.feedback"
      :state="perInput.group.valid"
    >
      <template #description>
        <expiration-interval-description :message="$options.i18n.groupRunnerDescription" />
      </template>
      <chronic-duration-input
        v-model="perInput.group.value"
        name="application_setting[group_runner_token_expiration_interval]"
        :state="perInput.group.valid"
        @valid="updateValidity(perInput.group, $event)"
      />
    </gl-form-group>
    <gl-form-group
      :label="$options.i18n.projectRunnerTitle"
      :invalid-feedback="perInput.project.feedback"
      :state="perInput.project.valid"
    >
      <template #description>
        <expiration-interval-description :message="$options.i18n.projectRunnerDescription" />
      </template>
      <chronic-duration-input
        v-model="perInput.project.value"
        name="application_setting[project_runner_token_expiration_interval]"
        :state="perInput.project.valid"
        @valid="updateValidity(perInput.project, $event)"
      />
    </gl-form-group>
  </div>
</template>
