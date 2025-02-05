<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlBadge, GlButton, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { head, tail } from 'lodash';
import { createAlert } from '~/alert';
import { s__, sprintf } from '~/locale';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import currentScopeQuery from '../graphql/queries/current_scope.query.graphql';
import enableKeyMutation from '../graphql/mutations/enable_key.mutation.graphql';
import confirmDisableMutation from '../graphql/mutations/confirm_action.mutation.graphql';

import ActionBtn from './action_btn.vue';

export default {
  components: {
    ActionBtn,
    GlBadge,
    GlButton,
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [timeagoMixin],
  props: {
    deployKey: {
      type: Object,
      required: true,
    },
    projectId: {
      type: String,
      required: false,
      default: null,
    },
  },
  apollo: {
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    currentScope: {
      query: currentScopeQuery,
    },
  },
  data() {
    return {
      projectsExpanded: false,
    };
  },
  computed: {
    projects() {
      return this.deployKey.deployKeysProjects;
    },
    firstProject() {
      return head(this.projects);
    },
    restProjects() {
      return tail(this.projects);
    },
    restProjectsTooltip() {
      return sprintf(s__('DeployKeys|Expand %{count} other projects'), {
        count: this.restProjects.length,
      });
    },
    restProjectsLabel() {
      return sprintf(s__('DeployKeys|+%{count} others'), { count: this.restProjects.length });
    },
    isEnabled() {
      return this.currentScope === 'enabledKeys';
    },
    isRemovable() {
      return (
        this.isEnabled && this.deployKey.destroyedWhenOrphaned && this.deployKey.almostOrphaned
      );
    },
    isExpandable() {
      return !this.projectsExpanded && this.restProjects.length > 1;
    },
    isExpanded() {
      return this.projectsExpanded || this.restProjects.length === 1;
    },
  },
  methods: {
    projectTooltipTitle(project) {
      return project.canPush
        ? s__('DeployKeys|Grant write permissions to this key')
        : s__('DeployKeys|Read access only');
    },
    toggleExpanded() {
      this.projectsExpanded = !this.projectsExpanded;
    },
    isCurrentProject({ project } = {}) {
      if (this.projectId !== null) {
        return Boolean(project?.id?.toString() === this.projectId);
      }

      return false;
    },
    projectName(project) {
      if (this.isCurrentProject(project)) {
        return s__('DeployKeys|Current project');
      }

      return project?.project?.fullName;
    },
    onEnableError(error) {
      createAlert({
        message: s__('DeployKeys|Error enabling deploy key'),
        captureError: true,
        error,
      });
    },
  },
  enableKeyMutation,
  confirmDisableMutation,
};
</script>

<template>
  <div
    class="gl-responsive-table-row deploy-key gl-items-start !gl-border-default gl-bg-subtle md:gl-pl-5 md:gl-pr-5"
  >
    <div class="table-section section-40">
      <div role="rowheader" class="table-mobile-header gl-self-start gl-font-bold gl-text-subtle">
        {{ s__('DeployKeys|Deploy key') }}
      </div>
      <div class="table-mobile-content" data-testid="key-container">
        <p class="title gl-font-semibold gl-text-subtle" data-testid="key-title-content">
          {{ deployKey.title }}
        </p>
        <dl class="gl-mb-0 gl-text-sm">
          <dt>{{ __('SHA256') }}</dt>
          <dd class="fingerprint" data-testid="key-sha256-fingerprint-content">
            {{ deployKey.fingerprintSha256 }}
          </dd>
          <template v-if="deployKey.fingerprint">
            <dt>
              {{ __('MD5') }}
            </dt>
            <dd class="fingerprint">
              {{ deployKey.fingerprint }}
            </dd>
          </template>
        </dl>
      </div>
    </div>
    <div class="table-section section-20 section-wrap">
      <div role="rowheader" class="table-mobile-header gl-font-bold gl-text-subtle">
        {{ s__('DeployKeys|Project usage') }}
      </div>
      <div class="table-mobile-content deploy-project-list gl-flex gl-flex-wrap">
        <template v-if="projects.length > 0">
          <gl-badge
            v-gl-tooltip
            :href="firstProject.project.fullPath"
            :title="projectTooltipTitle(firstProject)"
            :icon="firstProject.canPush ? 'lock-open' : 'lock'"
            class="deploy-project-label gl-mb-2 gl-mr-2 gl-truncate"
          >
            <span class="gl-truncate">{{ projectName(firstProject) }}</span>
          </gl-badge>

          <gl-badge
            v-if="isExpandable"
            v-gl-tooltip
            :title="restProjectsTooltip"
            class="deploy-project-label gl-mb-2 gl-mr-2 gl-truncate"
            href="#"
            @click.native="toggleExpanded"
          >
            <span class="gl-truncate">{{ restProjectsLabel }}</span>
          </gl-badge>

          <gl-badge
            v-for="deployKeysProject in restProjects"
            v-else-if="isExpanded"
            :key="deployKeysProject.project.fullPath"
            v-gl-tooltip
            :href="deployKeysProject.project.fullPath"
            :title="projectTooltipTitle(deployKeysProject)"
            :icon="deployKeysProject.canPush ? 'lock-open' : 'lock'"
            class="deploy-project-label gl-mb-2 gl-mr-2 gl-truncate"
          >
            <span class="gl-truncate">{{ projectName(deployKeysProject) }}</span>
          </gl-badge>
        </template>
        <span v-else class="gl-text-subtle">{{ __('None') }}</span>
      </div>
    </div>
    <div class="table-section section-15">
      <div role="rowheader" class="table-mobile-header gl-font-bold gl-text-subtle">
        {{ __('Created') }}
      </div>
      <div class="table-mobile-content key-created-at gl-text-subtle">
        <span v-gl-tooltip :title="tooltipTitle(deployKey.createdAt)">
          <gl-icon name="calendar" /> <span>{{ timeFormatted(deployKey.createdAt) }}</span>
        </span>
      </div>
    </div>
    <div class="table-section section-15">
      <div role="rowheader" class="table-mobile-header gl-font-bold gl-text-subtle">
        {{ __('Expires') }}
      </div>
      <div class="table-mobile-content key-expires-at gl-text-subtle">
        <span
          v-if="deployKey.expiresAt"
          v-gl-tooltip
          :title="tooltipTitle(deployKey.expiresAt)"
          data-testid="expires-at-tooltip"
        >
          <gl-icon name="calendar" /> <span>{{ timeFormatted(deployKey.expiresAt) }}</span>
        </span>
        <span v-else>
          <span data-testid="expires-never">{{ __('Never') }}</span>
        </span>
      </div>
    </div>
    <div class="table-section section-10 table-button-footer deploy-key-actions">
      <div class="btn-group table-action-buttons">
        <action-btn
          v-if="!isEnabled"
          :deploy-key="deployKey"
          :mutation="$options.enableKeyMutation"
          category="secondary"
          @error="onEnableError"
        >
          {{ __('Enable') }}
        </action-btn>
        <gl-button
          v-if="deployKey.editPath"
          v-gl-tooltip
          :href="deployKey.editPath"
          :title="__('Edit')"
          :aria-label="__('Edit')"
          data-container="body"
          icon="pencil"
          category="secondary"
        />
        <action-btn
          v-if="isRemovable"
          v-gl-tooltip
          :deploy-key="deployKey"
          :title="__('Remove')"
          :aria-label="__('Remove')"
          :mutation="$options.confirmDisableMutation"
          category="secondary"
          variant="danger"
          icon="remove"
          data-container="body"
        />
        <action-btn
          v-else-if="isEnabled"
          v-gl-tooltip
          :deploy-key="deployKey"
          :title="__('Disable')"
          :aria-label="__('Disable')"
          :mutation="$options.confirmDisableMutation"
          data-container="body"
          icon="cancel"
          category="secondary"
          variant="danger"
        />
      </div>
    </div>
  </div>
</template>
