<script>
import {
  GlAlert,
  GlButton,
  GlDrawer,
  GlForm,
  GlFormGroup,
  GlFormInput,
  GlIcon,
  GlLink,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';

export default {
  name: 'RunnerCloudForm',
  DRAWER_Z_INDEX,
  i18n: {
    title: s__('Runners|Google Cloud connection'),
    wifTitle: s__('Runners|Workload identity federation'),
    wifAlertText: s__(
      'Runners|These workload identity federation settings are also used by the Google Artifact Registry integration.',
    ),
    wifSetupDescription: s__(
      'Runners|Google Cloud workload identity federation must be set up for secure access without accounts or keys.',
    ),
    wifSetupText: s__('Runners|Set up workload identity federation'),
    cloudSetupDescription: s__(
      'Runners|Set up your Google Cloud project to use the runner. To improve security, use a dedicated Google Cloud project for CI/CD, separate from resources and identity management projects.',
    ),
    cloudSetupText: s__('Runners|Set up google cloud project'),
    iapLabel: s__('Runners|Identity provider audience'),
    iapHelpText: s__(
      'Runners|The full resource name of the workload identity provider in Google Cloud.',
    ),
    iapDescription:
      'For example: //iam.googleapis.com/projects/<project-number>/locations/global/workloadIdentityPools/<pool-id>/providers/<provider-id>.',
    iapDocsLink: s__('Runners|Where’s my identity provider audience?'),
    projectIdLabel: s__('Runners|Google Cloud project ID'),
    projectRunnerTitle: s__('Runners|Project for runner'),
    projectIdHelpText: s__('Runners|Project for the new runner.'),
    continueBtnText: s__('Runners|Continue to runner details'),
  },
  components: {
    GlAlert,
    GlButton,
    GlDrawer,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlIcon,
    GlLink,
  },
  data() {
    return {
      cloudConnection: {
        resourcePath: '',
        projectId: '',
      },
      showWifDrawer: false,
      showCloudProjectDrawer: false,
    };
  },
  methods: {
    onWifSetupClick() {
      if (this.showCloudProjectDrawer) {
        this.showCloudProjectDrawer = false;
      }

      this.showWifDrawer = true;
    },
    onCloudSetupClick() {
      if (this.showWifDrawer) {
        this.showWifDrawer = false;
      }

      this.showCloudProjectDrawer = true;
    },
    closeDrawers() {
      this.showWifDrawer = false;
      this.showCloudProjectDrawer = false;
    },
  },
};
</script>
<template>
  <div>
    <h2 class="gl-font-size-h2 gl-mb-4">{{ $options.i18n.title }}</h2>

    <div class="gl-mb-5 gl-pt-1">
      <h2 class="gl-font-size-h2 gl-mb-3">{{ $options.i18n.wifTitle }}</h2>
      <gl-alert :dismissible="false">{{ $options.i18n.wifAlertText }}</gl-alert>
    </div>

    <p class="gl-mb-3">{{ $options.i18n.wifSetupDescription }}</p>
    <gl-button class="gl-mb-5" data-testid="wif-setup-btn" @click="onWifSetupClick">
      {{ $options.i18n.wifSetupText }}
    </gl-button>

    <gl-form>
      <gl-form-group label-for="resource-name">
        <template #label>
          <div class="gl-mb-3">{{ $options.i18n.iapLabel }}</div>
          <span class="gl-font-weight-normal">{{ $options.i18n.iapHelpText }}</span>
        </template>
        <template #description>
          <span class="gl-display-block gl-mb-2">{{ $options.i18n.iapDescription }}</span>

          <gl-link
            href="https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects"
            target="_blank"
          >
            {{ $options.i18n.iapDocsLink }}
            <gl-icon name="external-link" />
          </gl-link>
        </template>
        <gl-form-input
          id="resource-name"
          v-model="cloudConnection.resourcePath"
          type="text"
          data-testid="resource-input"
        />
      </gl-form-group>
    </gl-form>

    <h2 class="gl-font-size-h2 gl-mb-3">{{ $options.i18n.projectRunnerTitle }}</h2>

    <p class="gl-mb-3">{{ $options.i18n.cloudSetupDescription }}</p>
    <gl-button class="gl-mb-5" data-testid="cloud-setup-btn" @click="onCloudSetupClick">
      {{ $options.i18n.cloudSetupText }}
    </gl-button>

    <gl-form>
      <gl-form-group label-for="project-id">
        <template #label>
          <div class="gl-mb-3">{{ $options.i18n.projectIdLabel }}</div>
          <span class="gl-font-weight-normal">{{ $options.i18n.projectIdHelpText }}</span>
        </template>
        <gl-form-input
          id="project-id"
          v-model="cloudConnection.projectId"
          type="text"
          data-testid="project-id-input"
        />
      </gl-form-group>
    </gl-form>

    <gl-button
      class="gl-float-right gl-mt-3"
      variant="confirm"
      data-testid="continue-btn"
      @click="$emit('continue', cloudConnection)"
    >
      {{ $options.i18n.continueBtnText }}
    </gl-button>

    <gl-drawer
      :open="showWifDrawer"
      :z-index="$options.DRAWER_Z_INDEX"
      data-testid="wif-drawer"
      @close="closeDrawers"
    >
      <template #title>
        <h2 class="gl-font-size-h2">{{ $options.i18n.wifSetupText }}</h2>
      </template>
      <template #default>
        <!-- todo, show script to copy -->
      </template>
    </gl-drawer>

    <gl-drawer
      :open="showCloudProjectDrawer"
      :z-index="$options.DRAWER_Z_INDEX"
      data-testid="cloud-drawer"
      @close="closeDrawers"
    >
      <template #title>
        <h2 class="gl-font-size-h2">{{ $options.i18n.cloudSetupText }}</h2>
      </template>
      <template #default>
        <!-- todo, show script to copy -->
      </template>
    </gl-drawer>
  </div>
</template>
