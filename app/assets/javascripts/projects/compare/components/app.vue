<script>
import {
  GlButton,
  GlFormGroup,
  GlFormRadioGroup,
  GlIcon,
  GlTooltipDirective,
  GlSprintf,
  GlLink,
} from '@gitlab/ui';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import csrf from '~/lib/utils/csrf';
import {
  I18N,
  COMPARE_OPTIONS,
  COMPARE_REVISIONS_DOCS_URL,
  COMPARE_OPTIONS_INPUT_NAME,
} from '../constants';
import RevisionCard from './revision_card.vue';

export default {
  csrf,
  components: {
    RevisionCard,
    GlButton,
    GlFormRadioGroup,
    GlFormGroup,
    GlIcon,
    GlLink,
    GlSprintf,
    PageHeading,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
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
    straight: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      from: {
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
    branchSelectionChanged() {
      return this.from.revision !== this.paramsFrom || this.to.revision !== this.paramsTo;
    },
    areBranchesDifferent() {
      return this.from.revision !== this.to.revision;
    },
    showMrButton() {
      return !this.branchSelectionChanged && (this.projectMergeRequestPath || this.createMrPath);
    },
    showMrStatusMessage() {
      return this.branchSelectionChanged && this.areBranchesDifferent;
    },
    mrButtonHref() {
      return this.projectMergeRequestPath || this.createMrPath;
    },
    mrButtonTestId() {
      return this.projectMergeRequestPath ? 'projectMrButton' : 'createMrButton';
    },
    mrButtonText() {
      return this.projectMergeRequestPath ? this.$options.i18n.viewMr : this.$options.i18n.openMr;
    },
  },
  methods: {
    onSelectProject({ direction, project }) {
      // direction is either 'from' or 'to'
      this[direction].refsProjectPath = project.refs_url;
      this[direction].selectedProject = { ...project };
    },
    onSelectRevision({ direction, revision }) {
      this[direction].revision = revision; // direction is either 'from' or 'to'
    },
    onSwapRevision() {
      [this.from, this.to] = [this.to, this.from]; // swaps 'from' and 'to'
    },
  },
  i18n: I18N,
  compareOptions: COMPARE_OPTIONS,
  docsLink: COMPARE_REVISIONS_DOCS_URL,
  inputName: COMPARE_OPTIONS_INPUT_NAME,
};
</script>

<template>
  <form class="js-signature-container" method="POST" :action="projectCompareIndexPath">
    <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />
    <page-heading :heading="$options.i18n.title">
      <template #description>
        <gl-sprintf :message="$options.i18n.subtitle">
          <template #bold="{ content }">
            <strong>{{ content }}</strong>
          </template>
          <template #link="{ content }">
            <gl-link target="_blank" :href="$options.docsLink" data-testid="help-link">{{
              content
            }}</gl-link>
          </template>
        </gl-sprintf>
      </template>
    </page-heading>
    <div class="compare-revision-cards gl-items-center @lg/panel:gl-flex @lg/panel:gl-flex-row">
      <revision-card
        data-testid="sourceRevisionCard"
        :refs-project-path="to.refsProjectPath"
        :revision-text="$options.i18n.source"
        params-name="to"
        :params-branch="to.revision"
        :projects="to.projects"
        :selected-project="to.selectedProject"
        disable-repo-dropdown
        @selectProject="onSelectProject"
        @selectRevision="onSelectRevision"
      />
      <gl-button
        v-gl-tooltip="$options.i18n.swapRevisions"
        class="gl-mx-3 gl-hidden gl-self-end @md/panel:gl-flex"
        :aria-label="$options.i18n.swap"
        data-testid="swapRevisionsButton"
        category="tertiary"
        @click="onSwapRevision"
      >
        <gl-icon name="substitute" />
      </gl-button>
      <gl-button
        v-gl-tooltip="$options.i18n.swapRevisions"
        class="gl-my-5 gl-flex gl-self-end @md/panel:gl-hidden"
        @click="onSwapRevision"
      >
        {{ $options.i18n.swap }}
      </gl-button>
      <revision-card
        data-testid="targetRevisionCard"
        :refs-project-path="from.refsProjectPath"
        :revision-text="$options.i18n.target"
        params-name="from"
        :params-branch="from.revision"
        :selected-project="from.selectedProject"
        @selectProject="onSelectProject"
        @selectRevision="onSelectRevision"
      />
    </div>
    <gl-form-group :label="$options.i18n.optionsLabel" class="gl-mt-4">
      <gl-form-radio-group
        v-model="isStraight"
        :options="$options.compareOptions"
        :name="$options.inputName"
        required
      />
    </gl-form-group>
    <div class="gl-flex gl-items-center gl-gap-3 gl-pb-4">
      <gl-button
        category="primary"
        variant="confirm"
        data-testid="compare-button"
        type="submit"
        class="js-no-auto-disable"
      >
        {{ $options.i18n.compare }}
      </gl-button>
      <gl-button v-if="showMrButton" :href="mrButtonHref" :data-testid="mrButtonTestId">
        {{ mrButtonText }}
      </gl-button>
      <span v-else-if="showMrStatusMessage" data-testid="mrStatusMessage">
        <gl-sprintf :message="$options.i18n.compareToCheckMr">
          <template #bold="{ content }">
            <strong>{{ content }}</strong>
          </template>
        </gl-sprintf>
      </span>
    </div>
  </form>
</template>
