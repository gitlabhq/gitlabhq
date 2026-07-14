<script>
import { GlAlert, GlButton, GlIcon, GlLink, GlSprintf } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  name: 'OfflineTransferApp',
  components: {
    GlAlert,
    GlButton,
    GlIcon,
    GlLink,
    GlSprintf,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    exportPath: {
      type: String,
      required: true,
    },
    importPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    exportsEnabled() {
      return this.glFeatures.offlineTransferExports;
    },
    importsEnabled() {
      return this.glFeatures.offlineTransferImports;
    },
  },
  i18n: {
    storageInfo: s__(
      'OfflineTransfer|Offline transfer requires a configured %{boldStart}AWS S3 object storage service%{boldEnd}. Set up your bucket and credentials before exporting.',
    ),
  },
  // TODO offline path https://gitlab.com/gitlab-org/gitlab/-/work_items/581225
  offlineTransferPath: helpPagePath('user/group/import/direct_transfer_migrations.md'),
  directTransferPath: helpPagePath('user/group/import/direct_transfer_migrations.md'),
};
</script>

<template>
  <div class="gl-my-5 gl-flex gl-flex-col gl-gap-6 gl-@container">
    <header>
      <h1 class="gl-heading-display">{{ s__('OfflineTransfer|Offline transfer') }}</h1>
      <p class="gl-text-lg" data-testid="offline-transfer-subheading">
        {{
          s__(
            'OfflineTransfer|Migrate groups and projects between GitLab instances that have no network connection between them. Export top-level groups that you own to an object storage you control, then import them into the destination GitLab instance.',
          )
        }}
      </p>
      <gl-link :href="$options.offlineTransferPath" target="_blank" show-external-icon>
        {{ s__('OfflineTransfer|Learn more about offline transfer') }}
      </gl-link>
    </header>

    <gl-alert variant="info" :dismissible="false">
      <gl-sprintf :message="$options.i18n.storageInfo">
        <template #bold="{ content }">
          <strong>{{ content }}</strong>
        </template>
      </gl-sprintf>
    </gl-alert>

    <div class="gl-flex gl-flex-col gl-gap-6 @md:gl-flex-row">
      <div
        v-if="exportsEnabled"
        class="gl-border gl-flex gl-flex-1 gl-flex-col gl-items-start gl-gap-3 gl-rounded-md gl-p-7 gl-pt-5"
      >
        <span class="gl-p-3">
          <gl-icon name="upload" />
        </span>
        <h2 class="gl-heading-3 gl-mb-0">{{ s__('OfflineTransfer|Export groups') }}</h2>
        <p class="gl-mb-3 gl-text-lg gl-text-subtle">
          {{
            s__('OfflineTransfer|Choose top-level groups to export to an object storage location.')
          }}
        </p>
        <gl-button
          variant="confirm"
          category="primary"
          :href="exportPath"
          data-testid="export-button"
        >
          {{ s__('OfflineTransfer|Start offline export') }}
        </gl-button>
      </div>

      <div
        v-if="importsEnabled"
        class="gl-border gl-flex gl-flex-1 gl-flex-col gl-items-start gl-gap-3 gl-rounded-md gl-p-7 gl-pt-5"
      >
        <span class="gl-p-3">
          <gl-icon name="download" />
        </span>
        <h2 class="gl-heading-3 gl-mb-0">{{ s__('OfflineTransfer|Import groups') }}</h2>
        <p class="gl-mb-3 gl-text-lg gl-text-subtle">
          {{
            s__('OfflineTransfer|Import groups from object storage that contains exported groups.')
          }}
        </p>
        <gl-button
          variant="confirm"
          category="primary"
          :href="importPath"
          data-testid="import-button"
        >
          {{ s__('OfflineTransfer|Start offline import') }}
        </gl-button>
      </div>
    </div>

    <div class="gl-border gl-mt-4 gl-flex gl-items-center gl-gap-4 gl-rounded-md gl-p-5">
      <span class="gl-p-3">
        <gl-icon name="comparison" />
      </span>
      <div class="gl-flex-1">
        <h2 class="gl-heading-4 gl-mb-3">
          {{ s__('OfflineTransfer|Do you need offline transfer?') }}
        </h2>
        <p class="gl-mb-2 gl-text-lg gl-leading-24 gl-text-subtle">
          {{
            s__(
              'OfflineTransfer|If your GitLab instances can access each other over a network, use direct transfer instead. Direct transfer migrates groups and projects directly without separate export and import steps.',
            )
          }}
        </p>
        <gl-link :href="$options.directTransferPath" target="_blank" show-external-icon>
          {{ s__('OfflineTransfer|Learn more') }}
        </gl-link>
      </div>
    </div>
  </div>
</template>
