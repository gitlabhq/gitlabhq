<script>
import { GlIcon, GlButton, GlBadge, GlTooltipDirective } from '@gitlab/ui';
import NumberToHumanSize from '~/vue_shared/components/number_to_human_size/number_to_human_size.vue';
import UserDate from '~/vue_shared/components/user_date.vue';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import { SHORT_DATE_FORMAT_WITH_TIME } from '~/vue_shared/constants';
import { s__ } from '~/locale';
import { joinPaths } from '~/lib/utils/url_utility';
import deletePagesDeploymentMutation from '../queries/delete_pages_deployment.mutation.graphql';
import restorePagesDeploymentMutation from '../queries/restore_pages_deployment.mutation.graphql';

export default {
  name: 'PrimaryDeployment',
  components: {
    UserDate,
    NumberToHumanSize,
    GlIcon,
    GlButton,
    GlBadge,
    TimeAgo,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  i18n: {
    deleteError: s__(
      'Pages|An error occurred while deleting the deployment. Check your connection and try again.',
    ),
    restoreError: s__(
      'Pages|Restoring the deployment failed. The deployment might be permanently deleted.',
    ),
    error: s__('Pages|Has error'),
    activeState: s__('Pages|Active'),
    stoppedState: s__('Pages|Stopped'),
    createdLabel: s__('Pages|Created'),
    deployJobLabel: s__('Pages|Deploy job'),
    rootDirLabel: s__('Pages|Root directory'),
    filesLabel: s__('Pages|Files'),
    sizeLabel: s__('Pages|Size'),
    lastUpdatedLabel: s__('Pages|Last updated'),
    deleteScheduledAtLabel: s__('Pages|Scheduled for deletion at'),
    deleteBtnLabel: s__('Pages|Delete'),
    restoreBtnLabel: s__('Pages|Restore'),
    expiresAtLabel: s__('Pages|Expires at'),
    neverExpires: s__('Pages|Never expires'),
  },
  static: {
    SHORT_DATE_FORMAT_WITH_TIME,
  },
  inject: ['projectFullPath'],
  props: {
    deployment: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      hasError: false,
      deleteInProgress: false,
      restoreInProgress: false,
      detailContainerHeight: 0,
    };
  },
  computed: {
    ciBuildUrl() {
      return joinPaths(
        gon.relative_url_root || '/',
        this.projectFullPath,
        '/-/jobs/',
        `${this.deployment.ciBuildId}`,
      );
    },
    formattedRootDirectory() {
      return `/${this.deployment.rootDirectory || 'public'}`;
    },
  },
  mounted() {
    this.calculateDetailHeight();
  },
  methods: {
    calculateDetailHeight() {
      this.detailContainerHeight = this.$refs.details?.scrollHeight;
    },
    async deleteDeployment() {
      this.hasError = false;
      this.deleteInProgress = true;
      try {
        await this.$apollo.mutate({
          mutation: deletePagesDeploymentMutation,
          variables: {
            deploymentId: this.deployment.id,
          },
        });
      } catch (error) {
        this.hasError = true;
        this.$emit('error', {
          id: this.deployment.id,
          message: this.$options.i18n.deleteError,
        });
      } finally {
        this.deleteInProgress = false;
        await this.$nextTick();
        this.calculateDetailHeight();
      }
    },
    async restoreDeployment() {
      this.hasError = false;
      this.restoreInProgress = true;
      try {
        await this.$apollo.mutate({
          mutation: restorePagesDeploymentMutation,
          variables: {
            deploymentId: this.deployment.id,
          },
        });
      } catch (e) {
        this.hasError = true;
        this.$emit('error', { id: this.deployment.id, message: this.$options.i18n.restoreError });
      } finally {
        this.restoreInProgress = false;
        await this.$nextTick();
        this.calculateDetailHeight();
      }
    },
  },
};
</script>

<template>
  <li
    class="!gl-grid gl-grid-cols-[1fr,1fr] gl-gap-2 gl-py-4 @md/panel:gl-grid-cols-[1fr,3fr,2fr] @md/panel:gl-gap-0"
  >
    <div
      class="gl-flex gl-flex-col gl-items-start gl-justify-center gl-gap-2 @md/panel:gl-justify-start"
      data-testid="deployment-state"
    >
      <gl-badge
        v-if="hasError"
        variant="danger"
        size="sm"
        icon="error"
        icon-size="sm"
        data-testid="error-badge"
      >
        {{ $options.i18n.error }}
      </gl-badge>
      <gl-badge
        v-if="deployment.active"
        variant="success"
        size="sm"
        icon="check-circle-filled"
        icon-size="sm"
      >
        {{ $options.i18n.activeState }}
      </gl-badge>
      <gl-badge v-else variant="neutral" size="sm" icon="status-stopped" icon-size="sm">
        {{ $options.i18n.stoppedState }}
      </gl-badge>
    </div>

    <div
      class="gl-col-start-1 gl-row-start-2 gl-flex gl-flex-col gl-gap-2 @md/panel:gl-col-start-2 @md/panel:gl-row-start-1"
    >
      <div data-testid="deployment-url">
        <a
          v-if="deployment.active"
          :href="deployment.url"
          target="_blank"
          class="gl-w-full gl-truncate !gl-text-link"
          @click.stop
        >
          {{ deployment.url }}
        </a>
        <span v-else class="gl-w-full gl-truncate gl-text-subtle">
          {{ deployment.url }}
        </span>
      </div>

      <p class="gl-mb-0" data-testid="deployment-ci-build-id">
        <gl-icon name="deployments" />
        <span class="gl-text-subtle">{{ $options.i18n.deployJobLabel }}:</span>
        <a :href="ciBuildUrl" class="!gl-text-link" @click.stop>
          {{ deployment.ciBuildId }}
        </a>
      </p>

      <p class="gl-mb-0 gl-flex gl-items-center gl-gap-2 gl-text-subtle">
        <gl-icon name="folder" />
        <span
          v-gl-tooltip
          :title="$options.i18n.rootDirLabel"
          data-testid="deployment-root-directory"
          >{{ formattedRootDirectory }}</span
        >
        <span aria-hidden="true">·</span>

        <span data-testid="deployment-file-count"
          >{{ deployment.fileCount }} {{ $options.i18n.filesLabel }}</span
        >
        <span aria-hidden="true">·</span>

        <span data-testid="deployment-size">
          {{ deployment.sizeLabel }}
          <number-to-human-size :value="deployment.size" />
        </span>
      </p>
    </div>

    <div
      class="gl-col-start-1 gl-row-start-3 gl-mt-3 gl-flex gl-flex-col gl-gap-2 @md/panel:gl-col-start-2 @md/panel:gl-flex-row @md/panel:gl-items-center"
    >
      <p class="gl-mb-0 gl-text-sm gl-text-subtle" data-testid="deployment-created-at">
        {{ $options.i18n.createdLabel }}
        <time-ago :time="deployment.createdAt" />
      </p>

      <template v-if="deployment.updatedAt">
        <span class="gl-hidden @md/panel:gl-inline" aria-hidden="true">·</span>
        <p class="gl-mb-0 gl-text-sm gl-text-subtle" data-testid="deployment-updated-at">
          {{ $options.i18n.lastUpdatedLabel }}
          <time-ago :time="deployment.updatedAt" />
        </p>
      </template>
    </div>

    <div
      class="gl-col-start-2 gl-row-start-1 gl-flex gl-flex-col gl-items-end gl-justify-between gl-gap-2 @md/panel:gl-col-start-3"
      data-testid="deployment-details"
    >
      <gl-button
        v-if="deployment.active"
        v-gl-tooltip
        icon="remove"
        category="tertiary"
        :title="$options.i18n.deleteBtnLabel"
        :loading="deleteInProgress"
        data-testid="deployment-delete"
        @click.stop="deleteDeployment"
      />
      <gl-button
        v-else
        v-gl-tooltip
        icon="redo"
        category="tertiary"
        :title="$options.i18n.restoreBtnLabel"
        :loading="restoreInProgress"
        data-testid="deployment-restore"
        @click.stop="restoreDeployment"
      />
    </div>

    <div
      class="gl-col-start-1 gl-row-start-4 gl-flex gl-flex-col gl-justify-between gl-gap-2 @md/panel:gl-col-start-3 @md/panel:gl-row-start-3 @md/panel:gl-mt-3 @md/panel:gl-items-end"
    >
      <template v-if="!deployment.active">
        <p class="gl-mb-0 gl-text-sm gl-text-danger">
          {{ $options.i18n.deleteScheduledAtLabel }}
          <user-date
            :date="deployment.deletedAt"
            :date-format="$options.static.SHORT_DATE_FORMAT_WITH_TIME"
          />
        </p>
      </template>
      <p v-else class="gl-mb-0 gl-text-sm gl-text-subtle" data-testid="deployment-expires-at">
        <template v-if="deployment.expiresAt">
          {{ $options.i18n.expiresAtLabel }}
          <user-date
            :date="deployment.expiresAt"
            :date-format="$options.static.SHORT_DATE_FORMAT_WITH_TIME"
          />
        </template>
        <template v-else>{{ $options.i18n.neverExpires }}</template>
      </p>
    </div>
  </li>
</template>
