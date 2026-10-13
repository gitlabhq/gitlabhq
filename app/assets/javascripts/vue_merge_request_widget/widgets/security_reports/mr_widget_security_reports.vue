<script>
import { GlDisclosureDropdown } from '@gitlab/ui';
import MrWidget from '~/vue_merge_request_widget/components/widget/widget.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__, sprintf } from '~/locale';
import { EXTENSION_ICONS } from '~/vue_merge_request_widget/constants';
import securityReportMergeRequestDownloadPathsQuery from './graphql/security_report_merge_request_download_paths.query.graphql';

export default {
  name: 'WidgetSecurityReportsCE',
  components: {
    MrWidget,
    GlDisclosureDropdown,
  },
  i18n: {
    apiError: s__(
      'SecurityReports|Failed to get security report information. Please reload the page or try again later.',
    ),
    scansHaveRun: s__('SecurityReports|Security scans have run'),
  },
  props: {
    mr: {
      type: Object,
      required: true,
    },
    level: {
      type: Number,
      required: false,
      default: 1,
    },
  },
  emits: ['loaded', 'empty'],
  data() {
    return {
      hasError: false,
    };
  },
  reportTypes: ['sast', 'secret_detection'],
  apollo: {
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    reportArtifacts: {
      query: securityReportMergeRequestDownloadPathsQuery,
      context: {
        featureCategory: 'vulnerability_management',
      },
      variables() {
        return {
          projectPath: this.mr.targetProjectFullPath,
          iid: String(this.mr.iid),
          reportTypes: this.$options.reportTypes.map((r) => r.toUpperCase()),
        };
      },
      update(data) {
        const artifacts = [];

        (data?.project?.mergeRequest?.headPipeline?.jobs?.nodes || []).forEach((reportType) => {
          reportType.artifacts?.nodes.forEach((artifact) => {
            if (artifact.fileType !== 'TRACE') {
              artifacts.push({
                name: reportType.name,
                id: reportType.id,
                path: artifact.downloadPath,
                fileType: artifact.fileType,
              });
            }
          });
        });

        if (artifacts.length) {
          this.$emit('loaded', 0, this.$options.icons.warning);
        }

        return artifacts;
      },
      error() {
        this.hasError = true;

        if (this.hasSecurityReports) {
          this.$emit('loaded', 0, this.$options.icons.failed);
        }
      },
    },
  },
  computed: {
    artifacts() {
      return this.reportArtifacts || [];
    },
    hasSecurityReports() {
      return this.artifacts.length > 0;
    },
    summary() {
      return { title: this.$options.i18n.scansHaveRun };
    },
    listboxOptions() {
      return this.artifacts
        .filter(({ name, path }) => name && path)
        .map(({ name, path, fileType }) => {
          const text = fileType
            ? sprintf(s__('SecurityReports|Download %{artifactName} (%{fileType})'), {
                artifactName: name,
                fileType: fileType.toLowerCase(),
              })
            : sprintf(s__('SecurityReports|Download %{artifactName}'), {
                artifactName: name,
              });

          return {
            text,
            href: path,
            extraAttrs: {
              download: '',
              rel: 'nofollow',
            },
          };
        });
    },
  },
  watch: {
    hasSecurityReports: {
      handler(hasSecurityReports) {
        this.$emit('empty', !hasSecurityReports);
      },
      immediate: true,
    },
  },
  methods: {
    handleIsLoading(value) {
      this.isLoading = value;
    },
  },
  widgetHelpPopover: {
    options: { title: s__('ciReport|Security scan results') },
    content: {
      text: s__(
        'ciReport|New vulnerabilities are vulnerabilities that the security scan detects in the merge request that are different to existing vulnerabilities in the default branch.',
      ),
      learnMorePath: helpPagePath('user/application_security/detect/security_scanning_results', {
        anchor: 'merge-request-reports',
      }),
    },
  },
  icons: EXTENSION_ICONS,
};
</script>

<template>
  <mr-widget
    v-if="hasSecurityReports"
    :level="level"
    :has-error="hasError"
    :error-text="$options.i18n.apiError"
    :status-icon-name="$options.icons.warning"
    :widget-name="$options.name"
    :is-collapsible="false"
    :help-popover="$options.widgetHelpPopover"
    :summary="summary"
    @is-loading="handleIsLoading"
  >
    <template #action-buttons>
      <gl-disclosure-dropdown
        class="gl-ml-3"
        size="small"
        icon="download"
        :items="listboxOptions"
        :fluid-width="true"
      />
    </template>
  </mr-widget>
</template>
