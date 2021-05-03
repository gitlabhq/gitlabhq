<script>
import { GlIcon, GlLink, GlTooltipDirective, GlButton } from '@gitlab/ui';
import { head, tail } from 'lodash';
import { s__, sprintf } from '~/locale';
import timeagoMixin from '~/vue_shared/mixins/timeago';

import actionBtn from './action_btn.vue';

export default {
  components: {
    actionBtn,
    GlButton,
    GlIcon,
    GlLink,
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
  <div class="gl-responsive-table-row deploy-key">
    <div class="table-section section-40">
      <div role="rowheader" class="table-mobile-header">{{ s__('DeployKeys|Deploy key') }}</div>
      <div class="table-mobile-content" data-qa-selector="key_container">
        <strong class="title" data-qa-selector="key_title_content"> {{ deployKey.title }} </strong>
        <div class="fingerprint" data-qa-selector="key_md5_fingerprint_content">
          {{ __('MD5') }}:{{ deployKey.fingerprint }}
        </div>
        <div class="fingerprint">{{ __('SHA256') }}:{{ deployKey.fingerprint_sha256 }}</div>
      </div>
    </div>
    <div class="table-section section-30 section-wrap">
      <div role="rowheader" class="table-mobile-header">{{ s__('DeployKeys|Project usage') }}</div>
      <div class="table-mobile-content deploy-project-list">
        <template v-if="projects.length > 0">
          <gl-link
            v-gl-tooltip
            :title="projectTooltipTitle(firstProject)"
            class="label deploy-project-label"
          >
            <span> {{ firstProject.project.full_name }} </span>
            <gl-icon :name="firstProject.can_push ? 'lock-open' : 'lock'" />
          </gl-link>
          <gl-link
            v-if="isExpandable"
            v-gl-tooltip
            :title="restProjectsTooltip"
            class="label deploy-project-label"
            @click="toggleExpanded"
          >
            <span>{{ restProjectsLabel }}</span>
          </gl-link>
          <gl-link
            v-for="deployKeysProject in restProjects"
            v-else-if="isExpanded"
            :key="deployKeysProject.project.full_path"
            v-gl-tooltip
            :href="deployKeysProject.project.full_path"
            :title="projectTooltipTitle(deployKeysProject)"
            class="label deploy-project-label"
          >
            <span> {{ deployKeysProject.project.full_name }} </span>
            <gl-icon :name="deployKeysProject.can_push ? 'lock-open' : 'lock'" />
          </gl-link>
        </template>
        <span v-else class="text-secondary">{{ __('None') }}</span>
      </div>
    </div>
    <div class="table-section section-15 text-right">
      <div role="rowheader" class="table-mobile-header">{{ __('Created') }}</div>
      <div class="table-mobile-content text-secondary key-created-at">
        <span v-gl-tooltip :title="tooltipTitle(deployKey.created_at)">
          <gl-icon name="calendar" /> <span>{{ timeFormatted(deployKey.created_at) }}</span>
        </span>
      </div>
    </div>
    <div class="table-section section-15 table-button-footer deploy-key-actions">
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
          category="primary"
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
          category="primary"
          variant="danger"
        />
      </div>
    </div>
  </div>
</template>
