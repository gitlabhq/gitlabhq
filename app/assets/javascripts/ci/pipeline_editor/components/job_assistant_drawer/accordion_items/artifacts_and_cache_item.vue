<script>
import { GlAccordionItem, GlFormInput, GlFormGroup, GlButton, GlLink, GlSprintf } from '@gitlab/ui';
import { get, toPath } from 'lodash';
import { i18n, HELP_PATHS } from '../constants';

export default {
  i18n,
  artifactsHelpPath: HELP_PATHS.artifactsHelpPath,
  cacheHelpPath: HELP_PATHS.cacheHelpPath,
  components: {
    GlFormGroup,
    GlAccordionItem,
    GlFormInput,
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
    formOptions() {
      return [
        {
          key: 'artifacts.paths',
          title: i18n.ARTIFACTS_PATHS,
          paths: this.job.artifacts.paths,
          generateInputDataTestId: (index) => `artifacts-paths-input-${index}`,
          generateDeleteButtonDataTestId: (index) => `delete-artifacts-paths-button-${index}`,
          addButtonDataTestId: 'add-artifacts-paths-button',
        },
        {
          key: 'artifacts.exclude',
          title: i18n.ARTIFACTS_EXCLUDE_PATHS,
          paths: this.job.artifacts.exclude,
          generateInputDataTestId: (index) => `artifacts-exclude-input-${index}`,
          generateDeleteButtonDataTestId: (index) => `delete-artifacts-exclude-button-${index}`,
          addButtonDataTestId: 'add-artifacts-exclude-button',
        },
        {
          key: 'cache.paths',
          title: i18n.CACHE_PATHS,
          paths: this.job.cache.paths,
          generateInputDataTestId: (index) => `cache-paths-input-${index}`,
          generateDeleteButtonDataTestId: (index) => `delete-cache-paths-button-${index}`,
          addButtonDataTestId: 'add-cache-paths-button',
        },
      ];
    },
  },
  methods: {
    deleteStringArrayItem(path) {
      const parentPath = toPath(path).slice(0, -1);
      const array = get(this.job, parentPath);
      if (array.length <= 1) {
        return;
      }
      this.$emit('update-job', path);
    },
  },
};
</script>
<template>
  <gl-accordion-item :title="$options.i18n.ARTIFACTS_AND_CACHE">
    <div class="gl-pb-5">
      <gl-sprintf :message="$options.i18n.ARTIFACTS_AND_CACHE_DESCRIPTION">
        <template #artifactsLink="{ content }">
          <gl-link :href="$options.artifactsHelpPath">{{ content }}</gl-link>
        </template>
        <template #cacheLink="{ content }">
          <gl-link :href="$options.cacheHelpPath">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </div>
    <div v-for="entry in formOptions" :key="entry.key" class="form-group">
      <div class="gl-flex">
        <label class="gl-mb-3 gl-font-bold">{{ entry.title }}</label>
      </div>
      <div
        v-for="(path, index) in entry.paths"
        :key="index"
        class="gl-mb-3 gl-flex gl-items-center"
      >
        <div class="gl-mr-3 gl-grow gl-basis-0">
          <gl-form-input
            class="!gl-w-full"
            :value="path"
            :data-testid="entry.generateInputDataTestId(index)"
            @input="$emit('update-job', `${entry.key}[${index}]`, $event)"
          />
        </div>
        <gl-button
          category="tertiary"
          icon="remove"
          :data-testid="entry.generateDeleteButtonDataTestId(index)"
          :aria-label="entry.generateDeleteButtonDataTestId(index)"
          @click="deleteStringArrayItem(`${entry.key}[${index}]`)"
        />
      </div>
      <gl-button
        category="secondary"
        variant="confirm"
        :data-testid="entry.addButtonDataTestId"
        @click="$emit('update-job', `${entry.key}[${entry.paths.length}]`, '')"
        >{{ $options.i18n.ADD_PATH }}</gl-button
      >
    </div>
    <gl-form-group :label="$options.i18n.CACHE_KEY">
      <gl-form-input
        :value="job.cache.key"
        data-testid="cache-key-input"
        @input="$emit('update-job', 'cache.key', $event)"
      />
    </gl-form-group>
  </gl-accordion-item>
</template>
