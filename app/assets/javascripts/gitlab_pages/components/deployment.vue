<script>
import { GlIcon, GlButton, GlBadge } from '@gitlab/ui';
import NumberToHumanSize from '~/vue_shared/components/number_to_human_size/number_to_human_size.vue';
import UserDate from '~/vue_shared/components/user_date.vue';
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
  },
  i18n: {
    deleteError: s__(
      'Pages|An error occurred while deleting the deployment. Check your connection and try again.',
    ),
    restoreError: s__(
      'Pages|Restoring the deployment failed. The deployment might be permanently deleted.',
    ),
    activeState: s__('Pages|Active'),
    stoppedState: s__('Pages|Stopped'),
    primaryDeploymentTitle: s__('Pages|Primary deployment'),
    pathPrefixLabel: s__('Pages|Path prefix'),
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
      showDetail: false,
      deleteInProgress: false,
      restoreInProgress: false,
      stateChanged: false,
      detailContainerHeight: 0,
    };
  },
  computed: {
    isPrimary() {
      return !this.deployment.pathPrefix;
    },
    detailHeight() {
      return this.showDetail ? this.detailContainerHeight : 0;
    },
    detailStyle() {
      return {
        height: `${this.detailHeight}px`,
        visibility: this.showDetail ? 'visible' : 'hidden',
      };
    },
    ciBuildUrl() {
      return joinPaths(
        gon.relative_url_root || '/',
        this.projectFullPath,
        '/-/jobs/',
        `${this.deployment.ciBuildId}`,
      );
    },
  },
  mounted() {
    this.calculateDetailHeight();
  },
  methods: {
    toggleDetail() {
      this.showDetail = !this.showDetail;
    },
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
  <div
    class="gl-border gl-flex gl-flex-col gl-gap-2 gl-rounded-lg gl-p-4"
    :class="{ 'gl-bg-blue-50': isPrimary, 'gl-border-red-500': hasError }"
    @click="toggleDetail"
  >
    <div class="gl-flex gl-items-center gl-justify-start gl-gap-3">
      <div class="gl-flex gl-justify-center gl-gap-3">
        <div data-testid="deployment-state">
          <gl-badge
            v-if="deployment.active"
            variant="info"
            size="sm"
            icon="status_success"
            icon-size="sm"
          >
            {{ $options.i18n.activeState }}
          </gl-badge>
          <gl-badge v-else variant="neutral" size="sm" icon="status_canceled" icon-size="sm">
            {{ $options.i18n.stoppedState }}
          </gl-badge>
        </div>
      </div>
    </div>
    <div
      class="gl-flex gl-flex-col gl-gap-4 gl-overflow-hidden md:gl-flex-row md:gl-items-center md:gl-justify-between md:gl-gap-7"
    >
      <div class="gl-flex gl-items-center gl-gap-4">
        <div>
          <gl-icon
            name="chevron-lg-right"
            :class="{ 'gl-rotate-90': showDetail }"
            class="reduce-motion:gl-transition-none gl-transition-transform"
            variant="subtle"
          />
        </div>
        <div data-testid="deployment-type" class="gl-flex gl-flex-col gl-gap-2 gl-text-nowrap">
          <template v-if="isPrimary">
            <gl-icon name="home" class="mr-1" variant="subtle" />
            <span class="sr-only">
              {{ $options.i18n.primaryDeploymentTitle }}
            </span>
          </template>
          <template v-else>
            <div class="gl-sr-only">{{ $options.i18n.pathPrefixLabel }}</div>
            <div>
              <gl-icon name="environment" class="mr-1" variant="subtle" />
              {{ deployment.pathPrefix }}
            </div>
          </template>
        </div>
        <div class="gl-flex gl-flex-col gl-gap-2 gl-truncate gl-text-nowrap">
          <div class="gl-flex gl-items-center gl-gap-2" data-testid="deployment-url">
            <a
              v-if="deployment.active"
              :href="deployment.url"
              target="_blank"
              class="gl-w-full gl-truncate"
              @click.stop
            >
              {{ deployment.url }}
            </a>
            <span v-else class="gl-w-full gl-truncate gl-text-subtle">
              {{ deployment.url }}
            </span>
          </div>
        </div>
      </div>
      <div class="gl-flex gl-flex-col gl-items-stretch gl-gap-5 md:gl-items-end">
        <div class="gl-flex gl-items-end gl-justify-between gl-gap-6 md:gl-justify-end">
          <div
            class="gl-flex gl-flex-col gl-gap-2 gl-text-nowrap"
            data-testid="deployment-created-at"
          >
            <div class="gl-text-sm gl-text-subtle">{{ $options.i18n.createdLabel }}</div>
            <div>
              <gl-icon name="play" class="mr-1" variant="subtle" />
              <user-date
                :date="deployment.createdAt"
                :date-format="$options.static.SHORT_DATE_FORMAT_WITH_TIME"
              />
            </div>
          </div>
        </div>
      </div>
    </div>
    <div
      ref="details"
      :style="detailStyle"
      data-testid="deployment-details"
      class="gl-flex gl-flex-col gl-gap-4 gl-overflow-hidden gl-transition-all motion-reduce:gl-transition-none md:gl-flex-row md:gl-gap-7"
    >
      <div class="gl-flex gl-flex-col gl-gap-2 gl-text-nowrap" data-testid="deployment-ci-build-id">
        <div class="gl-text-sm gl-text-subtle">{{ $options.i18n.deployJobLabel }}</div>
        <div>
          <gl-icon name="deployments" class="mr-1" variant="subtle" />
          <a :href="ciBuildUrl" @click.stop>
            {{ deployment.ciBuildId }}
          </a>
        </div>
      </div>
      <div
        class="gl-flex gl-flex-col gl-gap-2 gl-text-nowrap"
        data-testid="deployment-root-directory"
      >
        <div class="gl-text-sm gl-text-subtle">{{ $options.i18n.rootDirLabel }}</div>
        <div>
          <gl-icon name="folder" class="mr-1" variant="subtle" />
          /{{ deployment.rootDirectory || 'public' }}
        </div>
      </div>
      <div class="gl-flex gl-flex-col gl-gap-2 gl-text-nowrap" data-testid="deployment-file-count">
        <div class="gl-text-sm gl-text-subtle">{{ $options.i18n.filesLabel }}</div>
        <div>
          <gl-icon name="documents" class="mr-1" variant="subtle" />
          {{ deployment.fileCount }}
        </div>
      </div>
      <div class="gl-flex gl-flex-col gl-gap-2 gl-text-nowrap" data-testid="deployment-size">
        <div class="gl-text-sm gl-text-subtle">{{ $options.i18n.sizeLabel }}</div>
        <div>
          <gl-icon name="disk" class="mr-1" variant="subtle" />
          <number-to-human-size :value="deployment.size" />
        </div>
      </div>
      <div class="gl-flex gl-flex-col gl-gap-2 gl-text-nowrap" data-testid="deployment-updated-at">
        <div class="gl-text-sm gl-text-subtle">{{ $options.i18n.lastUpdatedLabel }}</div>
        <div>
          <gl-icon name="clear-all" class="mr-1" variant="subtle" />
          <user-date
            :date="deployment.updatedAt"
            :date-format="$options.static.SHORT_DATE_FORMAT_WITH_TIME"
          />
        </div>
      </div>
      <div
        v-if="deployment.active && deployment.expiresAt"
        class="gl-flex gl-flex-col gl-gap-2 gl-text-nowrap"
        data-testid="deployment-expires-at"
      >
        <div class="gl-text-sm gl-text-subtle">
          {{ $options.i18n.expiresAtLabel }}
        </div>
        <div>
          <gl-icon name="remove" class="gl-mr-2" variant="subtle" />
          <user-date
            :date="deployment.expiresAt"
            :date-format="$options.static.SHORT_DATE_FORMAT_WITH_TIME"
          />
        </div>
      </div>
      <div v-if="!deployment.active" class="gl-flex gl-flex-col gl-gap-2 gl-text-nowrap">
        <div class="gl-text-sm gl-text-subtle">
          {{ $options.i18n.deleteScheduledAtLabel }}
        </div>
        <div>
          <gl-icon name="remove" class="mr-1" variant="subtle" />
          <user-date
            :date="deployment.deletedAt"
            :date-format="$options.static.SHORT_DATE_FORMAT_WITH_TIME"
          />
        </div>
      </div>
      <div class="gl-hidden gl-flex-grow md:gl-block"></div>
      <div class="gl-flex gl-items-end md:gl-h-full">
        <gl-button
          v-if="deployment.active"
          icon="remove"
          category="secondary"
          variant="danger"
          size="small"
          :loading="deleteInProgress"
          data-testid="deployment-delete"
          @click.stop="deleteDeployment"
        >
          {{ $options.i18n.deleteBtnLabel }}
        </gl-button>
        <gl-button
          v-else
          icon="redo"
          category="secondary"
          variant="confirm"
          size="small"
          :loading="restoreInProgress"
          data-testid="deployment-restore"
          @click.stop="restoreDeployment"
        >
          {{ $options.i18n.restoreBtnLabel }}
        </gl-button>
      </div>
    </div>
  </div>
</template>

<style scoped></style>
