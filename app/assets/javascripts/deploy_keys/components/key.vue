<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlBadge, GlButton, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { head, tail } from 'lodash';
import { s__, sprintf } from '~/locale';
import timeagoMixin from '~/vue_shared/mixins/timeago';

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
    store: {
      type: Object,
      required: true,
    },
    endpoint: {
      type: String,
      required: true,
    },
    projectId: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      projectsExpanded: false,
    };
  },
  computed: {
    editDeployKeyPath() {
      return `${this.endpoint}/${this.deployKey.id}/edit`;
    },
    projects() {
      const projects = [...this.deployKey.deploy_keys_projects];

      if (this.projectId !== null) {
        const indexOfCurrentProject = projects.findIndex(
          (project) =>
            project &&
            project.project &&
            project.project.id &&
            project.project.id.toString() === this.projectId,
        );

        if (indexOfCurrentProject > -1) {
          const currentProject = projects.splice(indexOfCurrentProject, 1);
          currentProject[0].project.full_name = s__('DeployKeys|Current project');
          return currentProject.concat(projects);
        }
      }
      return projects;
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
      return this.store.isEnabled(this.deployKey.id);
    },
    isRemovable() {
      return (
        this.store.isEnabled(this.deployKey.id) &&
        this.deployKey.destroyed_when_orphaned &&
        this.deployKey.almost_orphaned
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
      return project.can_push
        ? s__('DeployKeys|Grant write permissions to this key')
        : s__('DeployKeys|Read access only');
    },
    toggleExpanded() {
      this.projectsExpanded = !this.projectsExpanded;
    },
  },
};
</script>

<template>
  <div
    class="gl-responsive-table-row gl-align-items-flex-start deploy-key gl-bg-gray-10 gl-md-pl-5 gl-md-pr-5 gl-border-gray-100!"
  >
    <div class="table-section section-40">
      <div
        role="rowheader"
        class="table-mobile-header gl-align-self-start gl-font-weight-bold gl-text-gray-700"
      >
        {{ s__('DeployKeys|Deploy key') }}
      </div>
      <div class="table-mobile-content" data-testid="key-container">
        <p class="title gl-font-weight-semibold gl-text-gray-700" data-testid="key-title-content">
          {{ deployKey.title }}
        </p>
        <dl class="gl-font-sm gl-mb-0">
          <dt>{{ __('SHA256') }}</dt>
          <dd class="fingerprint" data-testid="key-sha256-fingerprint-content">
            {{ deployKey.fingerprint_sha256 }}
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
      <div role="rowheader" class="table-mobile-header gl-font-weight-bold gl-text-gray-700">
        {{ s__('DeployKeys|Project usage') }}
      </div>
      <div class="table-mobile-content deploy-project-list gl-display-flex gl-flex-wrap">
        <template v-if="projects.length > 0">
          <gl-badge
            v-gl-tooltip
            :title="projectTooltipTitle(firstProject)"
            :icon="firstProject.can_push ? 'lock-open' : 'lock'"
            class="deploy-project-label gl-mr-2 gl-mb-2 gl-truncate"
          >
            <span class="gl-text-truncate">{{ firstProject.project.full_name }}</span>
          </gl-badge>

          <gl-badge
            v-if="isExpandable"
            v-gl-tooltip
            :title="restProjectsTooltip"
            class="deploy-project-label gl-mr-2 gl-mb-2 gl-truncate"
            href="#"
            @click.native="toggleExpanded"
          >
            <span class="gl-text-truncate">{{ restProjectsLabel }}</span>
          </gl-badge>

          <gl-badge
            v-for="deployKeysProject in restProjects"
            v-else-if="isExpanded"
            :key="deployKeysProject.project.full_path"
            v-gl-tooltip
            :href="deployKeysProject.project.full_path"
            :title="projectTooltipTitle(deployKeysProject)"
            :icon="deployKeysProject.can_push ? 'lock-open' : 'lock'"
            class="deploy-project-label gl-mr-2 gl-mb-2 gl-truncate"
          >
            <span class="gl-text-truncate">{{ deployKeysProject.project.full_name }}</span>
          </gl-badge>
        </template>
        <span v-else class="gl-text-secondary">{{ __('None') }}</span>
      </div>
    </div>
    <div class="table-section section-15">
      <div role="rowheader" class="table-mobile-header gl-font-weight-bold gl-text-gray-700">
        {{ __('Created') }}
      </div>
      <div class="table-mobile-content gl-text-gray-700 key-created-at">
        <span v-gl-tooltip :title="tooltipTitle(deployKey.created_at)">
          <gl-icon name="calendar" /> <span>{{ timeFormatted(deployKey.created_at) }}</span>
        </span>
      </div>
    </div>
    <div class="table-section section-15">
      <div role="rowheader" class="table-mobile-header gl-font-weight-bold gl-text-gray-700">
        {{ __('Expires') }}
      </div>
      <div class="table-mobile-content gl-text-gray-700 key-expires-at">
        <span
          v-if="deployKey.expires_at"
          v-gl-tooltip
          :title="tooltipTitle(deployKey.expires_at)"
          data-testid="expires-at-tooltip"
        >
          <gl-icon name="calendar" /> <span>{{ timeFormatted(deployKey.expires_at) }}</span>
        </span>
        <span v-else>
          <span data-testid="expires-never">{{ __('Never') }}</span>
        </span>
      </div>
    </div>
    <div class="table-section section-10 table-button-footer deploy-key-actions">
      <div class="btn-group table-action-buttons">
        <action-btn v-if="!isEnabled" :deploy-key="deployKey" type="enable" category="secondary">
          {{ __('Enable') }}
        </action-btn>
        <gl-button
          v-if="deployKey.can_edit"
          v-gl-tooltip
          :href="editDeployKeyPath"
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
          category="secondary"
          variant="danger"
          icon="remove"
          type="remove"
          data-container="body"
        />
        <action-btn
          v-else-if="isEnabled"
          v-gl-tooltip
          :deploy-key="deployKey"
          :title="__('Disable')"
          :aria-label="__('Disable')"
          type="disable"
          data-container="body"
          icon="cancel"
          category="secondary"
          variant="danger"
        />
      </div>
    </div>
  </div>
</template>
