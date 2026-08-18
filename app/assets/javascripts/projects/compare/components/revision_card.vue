<script>
import { glListenersMixin } from '~/lib/utils/vue3compat/gl_listeners_mixin';
import RepoDropdown from './repo_dropdown.vue';
import RevisionDropdown from './revision_dropdown.vue';

export default {
  name: 'RevisionCard',
  components: {
    RepoDropdown,
    RevisionDropdown,
  },
  mixins: [glListenersMixin],
  props: {
    refsProjectPath: {
      type: String,
      required: true,
    },
    revisionText: {
      type: String,
      required: true,
    },
    paramsName: {
      type: String,
      required: true,
    },
    paramsBranch: {
      type: String,
      required: false,
      default: null,
    },
    selectedProject: {
      type: Object,
      required: true,
    },
    disableRepoDropdown: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>

<template>
  <div class="revision-card gl-min-w-0 gl-basis-1/2">
    <h2 class="gl-mt-0 gl-text-base">
      {{ revisionText }}
    </h2>
    <div class="gl-flex gl-flex-col gl-gap-3 @sm/panel:gl-flex-row">
      <repo-dropdown
        class="gl-min-w-0 gl-max-w-full gl-basis-1/2"
        :params-name="paramsName"
        :selected-project="selectedProject"
        :disabled="disableRepoDropdown"
        v-on="glListeners()"
      />
      <revision-dropdown
        class="gl-min-w-0 gl-max-w-full gl-basis-1/2"
        :refs-project-path="refsProjectPath"
        :params-name="paramsName"
        :params-branch="paramsBranch"
        v-on="glListeners()"
      />
    </div>
  </div>
</template>
