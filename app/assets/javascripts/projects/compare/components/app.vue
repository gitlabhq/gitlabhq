<script>
import { GlDropdown, GlDropdownItem, GlButton } from '@gitlab/ui';
import csrf from '~/lib/utils/csrf';
import { joinPaths } from '~/lib/utils/url_utility';
import RevisionCard from './revision_card.vue';

export default {
  csrf,
  components: {
    RevisionCard,
    GlButton,
    GlDropdown,
    GlDropdownItem,
  },
  props: {
    projectCompareIndexPath: {
      type: String,
      required: true,
    },
    sourceProjectRefsPath: {
      type: String,
      required: true,
    },
    targetProjectRefsPath: {
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
    sourceProject: {
      type: Object,
      required: true,
    },
    targetProject: {
      type: Object,
      required: true,
    },
    projects: {
      type: Array,
      required: true,
    },
    straight: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      from: {
        projects: this.projects,
        selectedProject: this.targetProject,
        revision: this.paramsFrom,
        refsProjectPath: this.targetProjectRefsPath,
      },
      to: {
        selectedProject: this.sourceProject,
        revision: this.paramsTo,
        refsProjectPath: this.sourceProjectRefsPath,
      },
      isStraight: this.straight,
    };
  },
  computed: {
    straightModeDropdownItems() {
      return [
        {
          modeType: 'off',
          isEnabled: false,
          content: '..',
          testId: 'disableStraightModeButton',
        },
        {
          modeType: 'on',
          isEnabled: true,
          content: '...',
          testId: 'enableStraightModeButton',
        },
      ];
    },
  },
  methods: {
    onSubmit() {
      this.$refs.form.submit();
    },
    onSelectProject({ direction, project }) {
      const refsPath = joinPaths(gon.relative_url_root || '', `/${project.name}`, '/refs');
      // direction is either 'from' or 'to'
      this[direction].refsProjectPath = refsPath;
      this[direction].selectedProject = project;
    },
    onSelectRevision({ direction, revision }) {
      this[direction].revision = revision; // direction is either 'from' or 'to'
    },
    onSwapRevision() {
      [this.from, this.to] = [this.to, this.from]; // swaps 'from' and 'to'
    },
    setStraightMode(isStraight) {
      this.isStraight = isStraight;
    },
  },
};
</script>

<template>
  <form
    ref="form"
    class="js-requires-input js-signature-container"
    method="POST"
    :action="projectCompareIndexPath"
  >
    <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />
    <div
      class="gl-lg-flex-direction-row gl-lg-display-flex gl-align-items-center compare-revision-cards"
    >
      <revision-card
        data-testid="sourceRevisionCard"
        :refs-project-path="to.refsProjectPath"
        :revision-text="__('Source')"
        params-name="to"
        :params-branch="to.revision"
        :projects="to.projects"
        :selected-project="to.selectedProject"
        @selectProject="onSelectProject"
        @selectRevision="onSelectRevision"
      />
      <div
        class="gl-display-flex gl-justify-content-center gl-align-items-center gl-align-self-end gl-my-3 gl-md-my-0 gl-pl-3 gl-pr-3"
        data-testid="ellipsis"
      >
        <input :value="isStraight ? 'true' : 'false'" type="hidden" name="straight" />
        <gl-dropdown data-testid="modeDropdown" :text="isStraight ? '...' : '..'" size="small">
          <gl-dropdown-item
            v-for="mode in straightModeDropdownItems"
            :key="mode.modeType"
            :is-check-item="true"
            :is-checked="isStraight == mode.isEnabled"
            :data-testid="mode.testId"
            @click="setStraightMode(mode.isEnabled)"
          >
            <span class="dropdown-menu-inner-content"> {{ mode.content }} </span>
          </gl-dropdown-item>
        </gl-dropdown>
      </div>
      <revision-card
        data-testid="targetRevisionCard"
        :refs-project-path="from.refsProjectPath"
        :revision-text="__('Target')"
        params-name="from"
        :params-branch="from.revision"
        :projects="from.projects"
        :selected-project="from.selectedProject"
        @selectProject="onSelectProject"
        @selectRevision="onSelectRevision"
      />
    </div>
    <div class="gl-display-flex gl-mt-6 gl-gap-3">
      <gl-button category="primary" variant="confirm" @click="onSubmit">
        {{ s__('CompareRevisions|Compare') }}
      </gl-button>
      <gl-button data-testid="swapRevisionsButton" @click="onSwapRevision">
        {{ s__('CompareRevisions|Swap revisions') }}
      </gl-button>
      <gl-button
        v-if="projectMergeRequestPath"
        :href="projectMergeRequestPath"
        data-testid="projectMrButton"
      >
        {{ s__('CompareRevisions|View open merge request') }}
      </gl-button>
      <gl-button v-else-if="createMrPath" :href="createMrPath" data-testid="createMrButton">
        {{ s__('CompareRevisions|Create merge request') }}
      </gl-button>
    </div>
  </form>
</template>
