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
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { s__ } from '~/locale';
import { integrationTypes } from '../constants';

export default {
  i18n: {
    integrationsInfo: s__(
      'AlertSettings|Learn more about our upcoming %{linkStart}integrations%{linkEnd}',
    ),
    integrationFormSteps: {
      step1: { title: s__('AlertSettings|1. Select integration type') },
      step2: { title: s__('AlertSettings|2. Name integration') },
      step5: {
        title: s__('AlertSettings|5. Map fields (optional)'),
        intro: s__(
          'AlertSettings|The default GitLab alert keys are listed below. In the event an exact match could be found in the sample payload provided, that key will be mapped automatically. In all other cases, please define which payload key should map to the specified GitLab key. Any payload keys not shown in this list will not display in the alert list, but will display on the alert details page.',
        ),
      },
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
  mixins: [glFeatureFlagsMixin()],
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
      :label="$options.i18n.integrationFormSteps.step1.title"
      label-for="integration-type"
    >
      <gl-form-select
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
        :label="$options.i18n.integrationFormSteps.step2.title"
        label-for="name-integration"
      >
        <gl-form-input
          v-model="form.name"
          type="text"
          :placeholder="s__('AlertSettings|Enter integration name')"
        />
      </gl-form-group>

      <gl-form-group
        v-if="glFeatures.multipleHttpIntegrationsCustomMapping"
        id="mapping-builder"
        :label="$options.i18n.integrationFormSteps.step5.title"
        label-for="mapping-builder"
      >
        <span class="gl-text-gray-500">{{ $options.i18n.integrationFormSteps.step5.intro }}</span>
        <!--mapping builder will be added here-->
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
