<script>
import { GlButton } from '@gitlab/ui';
import csrf from '~/lib/utils/csrf';
import RevisionDropdown from './revision_dropdown_legacy.vue';

export default {
  csrf,
  components: {
    RevisionDropdown,
    GlButton,
  },
  props: {
    projectCompareIndexPath: {
      type: String,
      required: true,
    },
    refsProjectPath: {
      type: String,
      required: true,
    },
    paramsFrom: {
      type: String,
      required: false,
      default: null,
    },
    paramsTo: {
      type: String,
      required: false,
      default: null,
    },
    projectMergeRequestPath: {
      type: String,
      required: true,
    },
    createMrPath: {
      type: String,
      required: true,
    },
  },
  methods: {
    onSubmit() {
      this.$refs.form.submit();
    },
  },
};
</script>

<template>
  <form
    ref="form"
    class="form-inline js-requires-input js-signature-container"
    method="POST"
    :action="projectCompareIndexPath"
  >
    <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />
    <revision-dropdown
      :refs-project-path="refsProjectPath"
      revision-text="Source"
      params-name="to"
      :params-branch="paramsTo"
    />
    <div class="compare-ellipsis gl-display-inline" data-testid="ellipsis">...</div>
    <revision-dropdown
      :refs-project-path="refsProjectPath"
      revision-text="Target"
      params-name="from"
      :params-branch="paramsFrom"
    />
    <gl-button category="primary" variant="success" class="gl-ml-3" @click="onSubmit">
      {{ s__('CompareRevisions|Compare') }}
    </gl-button>
    <gl-button
      v-if="projectMergeRequestPath"
      :href="projectMergeRequestPath"
      data-testid="projectMrButton"
      class="btn btn-default gl-button gl-ml-3"
    >
      {{ s__('CompareRevisions|View open merge request') }}
    </gl-button>
    <gl-button
      v-else-if="createMrPath"
      :href="createMrPath"
      data-testid="createMrButton"
      class="btn btn-default gl-button gl-ml-3"
    >
      {{ s__('CompareRevisions|Create merge request') }}
    </gl-button>
  </form>
</template>
