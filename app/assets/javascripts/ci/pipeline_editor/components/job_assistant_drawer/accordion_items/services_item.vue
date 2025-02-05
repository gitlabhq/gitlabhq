<script>
import {
  GlAccordionItem,
  GlFormInput,
  GlButton,
  GlFormGroup,
  GlFormTextarea,
  GlLink,
  GlSprintf,
} from '@gitlab/ui';
import { i18n, HELP_PATHS } from '../constants';

export default {
  i18n,
  helpPath: HELP_PATHS.servicesHelpPath,
  placeholderText: i18n.ENTRYPOINT_PLACEHOLDER_TEXT,
  components: {
    GlAccordionItem,
    GlFormGroup,
    GlFormInput,
    GlFormTextarea,
    GlButton,
    GlLink,
    GlSprintf,
  },
  props: {
    job: {
      type: Object,
      required: true,
    },
  },
  computed: {
    canDeleteServices() {
      return this.job.services.length > 1;
    },
  },
  methods: {
    deleteService(index) {
      if (!this.canDeleteServices) {
        return;
      }
      this.$emit('update-job', `services[${index}]`);
    },
    addService() {
      this.$emit('update-job', `services[${this.job.services.length}]`, {
        name: '',
        entrypoint: [''],
      });
    },
    serviceEntryPoint(service) {
      const { entrypoint = [''] } = service;
      return entrypoint.join('\n');
    },
  },
};
</script>
<template>
  <gl-accordion-item :title="$options.i18n.SERVICE">
    <div class="gl-pb-5">
      <gl-sprintf :message="$options.i18n.SERVICES_DESCRIPTION">
        <template #link="{ content }">
          <gl-link :href="$options.helpPath">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </div>
    <div
      v-for="(service, index) in job.services"
      :key="index"
      class="gl-relative gl-mb-5 gl-bg-subtle gl-p-5"
    >
      <gl-button
        v-if="canDeleteServices"
        class="gl-absolute gl-right-3 gl-top-3"
        category="tertiary"
        icon="remove"
        :data-testid="`delete-job-service-button-${index}`"
        :aria-label="`delete-job-service-button-${index}`"
        @click="deleteService(index)"
      />
      <gl-form-group :label="$options.i18n.SERVICE_NAME">
        <gl-form-input
          :data-testid="`service-name-input-${index}`"
          :value="service.name"
          @input="$emit('update-job', `services[${index}].name`, $event)"
        />
      </gl-form-group>
      <gl-form-group
        :label="$options.i18n.SERVICE_ENTRYPOINT"
        :description="$options.i18n.ARRAY_FIELD_DESCRIPTION"
        class="gl-mb-0"
      >
        <gl-form-textarea
          :no-resize="false"
          :placeholder="$options.placeholderText"
          :data-testid="`service-entrypoint-input-${index}`"
          :value="serviceEntryPoint(service)"
          @input="$emit('update-job', `services[${index}].entrypoint`, $event.split('\n'))"
        />
      </gl-form-group>
    </div>
    <gl-button
      category="secondary"
      variant="confirm"
      data-testid="add-job-service-button"
      @click="addService"
      >{{ $options.i18n.ADD_SERVICE }}</gl-button
    >
  </gl-accordion-item>
</template>
