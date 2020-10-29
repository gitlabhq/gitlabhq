<script>
import {
  GlButton,
  GlCollapse,
  GlForm,
  GlFormGroup,
  GlFormSelect,
  GlFormInput,
  GlLink,
  GlSprintf,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import { integrationTypes } from '../constants';

export default {
  i18n: {
    integrationsInfo: s__(
      'AlertSettings|Learn more about our upcoming %{linkStart}integrations%{linkEnd}',
    ),
    integrationFormSteps: {
      step1: s__('AlertSettings|1. Select integration type'),
      step2: s__('AlertSettings|2. Name integration'),
    },
  },
  components: {
    GlButton,
    GlCollapse,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlFormSelect,
    GlLink,
    GlSprintf,
  },
  data() {
    return {
      selectedIntegration: integrationTypes[0].value,
      options: integrationTypes,
      formVisible: false,
      form: {
        name: '',
      },
    };
  },
  methods: {
    onIntegrationTypeSelect() {
      if (this.selectedIntegration === integrationTypes[0].value) {
        this.formVisible = false;
      } else {
        this.formVisible = true;
      }
    },
    onSubmit() {
      // TODO Add GraphQL method
    },
    onReset() {
      this.form.name = '';
    },
  },
};
</script>

<template>
  <gl-form class="gl-mt-6" @submit.prevent="onSubmit" @reset.prevent="onReset">
    <h5 class="gl-font-lg gl-my-5">{{ s__('AlertSettings|Add new integrations') }}</h5>

    <gl-form-group
      id="integration-type"
      :label="$options.i18n.integrationFormSteps.step1"
      label-for="integration-type"
    >
      <gl-form-select
        id="integration-type"
        v-model="selectedIntegration"
        :options="options"
        @change="onIntegrationTypeSelect"
      />
      <span class="gl-text-gray-500">
        <gl-sprintf :message="$options.i18n.integrationsInfo">
          <template #link="{ content }">
            <gl-link
              class="gl-display-inline-block"
              href="https://gitlab.com/groups/gitlab-org/-/epics/4390"
              target="_blank"
              >{{ content }}</gl-link
            >
          </template>
        </gl-sprintf>
      </span>
    </gl-form-group>
    <gl-collapse v-model="formVisible" class="gl-mt-3">
      <gl-form-group
        id="name-integration"
        :label="$options.i18n.integrationFormSteps.step2"
        label-for="name-integration"
      >
        <gl-form-input
          id="name-integration"
          v-model="form.name"
          type="text"
          :placeholder="s__('AlertSettings|Enter integration name')"
        />
      </gl-form-group>
      <div class="gl-display-flex gl-justify-content-end">
        <gl-button type="reset" class="gl-mr-3 js-no-auto-disable">{{ __('Cancel') }}</gl-button>
        <gl-button
          type="submit"
          category="secondary"
          variant="success"
          class="gl-mr-1 js-no-auto-disable"
          >{{ __('Save and test payload') }}</gl-button
        >
        <gl-button type="submit" variant="success" class="js-no-auto-disable">{{
          s__('AlertSettings|Save integration')
        }}</gl-button>
      </div>
    </gl-collapse>
  </gl-form>
</template>
