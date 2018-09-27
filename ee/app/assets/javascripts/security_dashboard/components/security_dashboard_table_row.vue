<script>
import { SkeletonLoading } from '@gitlab-org/gitlab-ui';
import SeverityBadge from 'ee/vue_shared/security_reports/components/severity_badge.vue';
import SecurityDashboardActionButtons from './security_dashboard_action_buttons.vue';

export default {
  name: 'SecurityDashboardTableRow',
  components: {
    SeverityBadge,
    SecurityDashboardActionButtons,
    SkeletonLoading,
  },
  props: {
    vulnerability: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    confidence() {
      return this.vulnerability.confidence || '–';
    },
    severity() {
      return this.vulnerability.severity || ' ';
    },
    projectNamespace() {
      const { project } = this.vulnerability;
      return project && project.name_with_namespace ? project.name_with_namespace : null;
    },
  },
};
</script>

<template>
  <div class="gl-responsive-table-row vulnerabilities-row">
    <div class="table-section section-10">
      <div
        class="table-mobile-header"
        role="rowheader"
      >
        {{ s__('Reports|Severity') }}
      </div>
      <div class="table-mobile-content">
        <severity-badge :severity="severity"/>
      </div>
    </div>

    <div class="table-section section-60">
      <div
        class="table-mobile-header"
        role="rowheader"
      >
        {{ s__('Reports|Vulnerability') }}
      </div>
      <div class="table-mobile-content">
        <skeleton-loading
          v-if="isLoading"
          class="mt-2 js-skeleton-loader"
          :lines="2"
        />
        <div v-else>
          <span>{{ vulnerability.description }}</span>
          <br />
          <span
            v-if="projectNamespace"
            class="vulnerability-namespace">
            {{ projectNamespace }}
          </span>
        </div>
      </div>
    </div>

    <div class="table-section section-10">
      <div
        class="table-mobile-header"
        role="rowheader"
      >
        {{ s__('Reports|Confidence') }}
      </div>
      <div class="table-mobile-content text-capitalize">
        {{ confidence }}
      </div>
    </div>

    <!-- This is hidden till we can hook up the actions
    <div class="table-section section-20">
      <div
        class="table-mobile-header"
        role="rowheader"
      >
        {{ s__('Reports|Actions') }}
      </div>
      <div class="table-mobile-content vulnerabilities-action-buttons">
        <security-dashboard-action-buttons
          :vulnerability="vulnerability"
        />
      </div>
    </div>
    -->
  </div>
</template>

<style>
@media (min-width: 768px) {
  .vulnerabilities-row {
    padding: 0.6em 0.4em;
  }

  .vulnerabilities-row:hover,
  .vulnerabilities-row:focus {
    background: #f6fafd;
    border-bottom: 1px solid #c1daf4;
    border-top: 1px solid #c1daf4;
    margin-top: -1px;
  }

  .vulnerabilities-row .vulnerabilities-action-buttons {
    opacity: 0;
    padding-right: 1em;
    text-align: right;
  }

  .vulnerabilities-row:hover .vulnerabilities-action-buttons,
  .vulnerabilities-row:focus .vulnerabilities-action-buttons {
    opacity: 1;
  }
}

.vulnerabilities-row .table-section {
  white-space: normal;
}

.vulnerability-namespace {
  color: #707070;
  font-size: 0.8em;
}
</style>
