<script>
import {
  GlAlert,
  GlButton,
  GlFormInput,
  GlFormGroup,
  GlLink,
  GlIcon,
  GlModal,
  GlPopover,
  GlSprintf,
} from '@gitlab/ui';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { createAlert } from '~/alert';
import { s__, __ } from '~/locale';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_CI_RUNNER } from '~/graphql_shared/constants';
import runnerForRegistrationQuery from '../../graphql/register/runner_for_registration.query.graphql';
import provisionGoogleCloudRunnerProject from '../../graphql/register/provision_google_cloud_runner_project.query.graphql';
import {
  I18N_FETCH_ERROR,
  STATUS_ONLINE,
  RUNNER_REGISTRATION_POLLING_INTERVAL_MS,
} from '../../constants';
import { captureException } from '../../sentry_utils';

export default {
  name: 'GoogleCloudRegistrationInstructions',
  i18n: {
    heading: s__('Runners|Register runner'),
    headingDescription: s__(
      'Runners|After you complete the steps below, an autoscaling fleet of runners is available to execute your CI/CD jobs in Google Cloud. Based on demand, a runner manager automatically creates temporary runners.',
    ),
    beforeHeading: s__('Runners|Before you begin'),
    permissionsText: s__(
      'Runners|Ensure you have the %{linkStart}Owner%{linkEnd} IAM role on your Google Cloud project.',
    ),
    billingLinkText: s__(
      'Runners|Ensure that %{linkStart}billing is enabled for your Google Cloud project%{linkEnd}.',
    ),
    preInstallText: s__(
      'Runners|To follow the setup instructions, %{gcloudLinkStart}install the Google Cloud CLI%{gcloudLinkEnd} and %{terraformLinkStart}install Terraform%{terraformLinkEnd}.',
    ),
    stepOneHeading: s__('Runners|Step 1: Specify environment'),
    stepOneDescription: s__(
      'Runners|Environment in Google Cloud where runners execute CI/CD jobs. Runners are created in temporary virtual machines based on demand.',
    ),
    stepTwoHeading: s__('Runners|Step 2: Set up GitLab Runner'),
    stepTwoDescription: s__(
      'Runners|To view the setup instructions, complete the previous form. The instructions help you set up an autoscaling fleet of runners to execute your CI/CD jobs in Google Cloud.',
    ),
    projectIdLabel: s__('Runners|Google Cloud project ID'),
    projectIdDescription: s__(
      'Runners|To improve security, use a dedicated project for CI/CD, separate from resources and identity management projects. %{linkStart}Where’s my project ID in Google Cloud?%{linkEnd}',
    ),
    regionLabel: s__('Runners|Region'),
    regionHelpText: s__('Runners|Specific geographical location where you can run your resources.'),
    learnMore: s__('Runners|Learn more in the %{linkStart}Google Cloud documentation%{linkEnd}.'),
    zoneLabel: s__('Runners|Zone'),
    zoneHelpText: s__(
      'Runners|Isolated location within a region. The zone determines what computing resources are available and where your data is stored and used.',
    ),
    zonesLinkText: s__('Runners|View available zones'),
    machineTypeLabel: s__('Runners|Machine type'),
    machineTypeHelpText: s__(
      'Runners|Machine type with preset amounts of virtual machines processors (vCPUs) and memory',
    ),
    machineTypeDescription: s__(
      'Runners|For most CI/CD jobs, use a %{linkStart}N2D standard machine type.%{linkEnd}',
    ),
    runnerSetupBtnText: s__('Runners|Setup instructions'),
    modal: {
      subtitle: s__(
        'Runners|These setup instructions use your specifications and follow the best practices for performance and security',
      ),
      step2_1Header: s__('Runners|Step 1: Configure Google Cloud project'),
      step2_1Body: s__(
        `Runners|If you haven't already configured your Google Cloud project, this step enables the required services and creates a service account with the required permissions. `,
      ),
      step2_1Substep1: s__(
        'Runners|Run the following on your command line. You might be prompted to sign in to Google',
      ),
      step2_2Header: s__('Runners|Step 2: Install and register GitLab Runner'),
      step2_2Body: s__(
        'Runners|This step creates the required infrastructure in Google Cloud, installs GitLab Runner, and registers it to this GitLab project. ',
      ),
      step2_2Substep1: s__(
        'Runners|Use a text editor to create a main.tf file with the following Terraform configuration',
      ),
      step2_2Substep2: s__(
        'Runners|In the directory with that Terraform configuration file, run the following on your command line.',
      ),
      step2_2Substep3: s__(
        'Runners|After GitLab Runner is installed and registered, an autoscaling fleet of runners is available to execute your CI/CD jobs in Google Cloud',
      ),
    },
    alertBody: s__('Runners|To view the setup instructions, complete the previous form'),
    invalidFormButton: s__('Runners|Go to first invalid form field'),
    externalLink: __('(external link)'),
  },
  links: {
    permissionsLink: 'https://cloud.google.com/iam/docs/understanding-roles#owner',
    billingLink:
      'https://cloud.google.com/billing/docs/how-to/verify-billing-enabled#confirm_billing_is_enabled_on_a_project',
    gcloudLink: 'https://cloud.google.com/sdk/docs/install',
    terraformLink: 'https://developer.hashicorp.com/terraform/install',
    projectIdLink:
      'https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects',
    regionAndZonesLink: 'https://cloud.google.com/compute/docs/regions-zones',
    zonesLink: 'https://console.cloud.google.com/compute/zones?pli=1',
    machineTypesLink:
      'https://cloud.google.com/compute/docs/general-purpose-machines#n2d_machine_types',
  },
  components: {
    ClipboardButton,
    GlAlert,
    GlButton,
    GlFormInput,
    GlFormGroup,
    GlIcon,
    GlLink,
    GlModal,
    GlPopover,
    GlSprintf,
  },
  props: {
    runnerId: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: false,
      default: '',
    },
    groupPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      projectId: '',
      region: '',
      zone: '',
      machineType: 'n2d-standard-2',
      token: '',
      runner: null,
      showInstructionsModal: false,
      validations: {
        projectId: false,
        region: false,
        zone: false,
      },
      provisioningSteps: [],
      setupBashScript: '',
      showAlert: false,
    };
  },
  apollo: {
    runner: {
      query: runnerForRegistrationQuery,
      variables() {
        return {
          id: convertToGraphQLId(TYPENAME_CI_RUNNER, this.runnerId),
        };
      },
      manual: true,
      result({ data }) {
        if (data?.runner) {
          const { ephemeralAuthenticationToken, ...runner } = data.runner;
          this.runner = runner;

          // The token is available in the API for a limited amount of time
          // preserve its original value if it is missing after polling.
          this.token = ephemeralAuthenticationToken || this.token;
        }
      },
      error(error) {
        createAlert({ message: I18N_FETCH_ERROR });
        captureException({ error, component: this.$options.name });
      },
      pollInterval() {
        if (this.isRunnerOnline) {
          // stop polling
          return 0;
        }
        return RUNNER_REGISTRATION_POLLING_INTERVAL_MS;
      },
    },
    project: {
      query: provisionGoogleCloudRunnerProject,
      variables() {
        return {
          fullPath: this.projectPath,
          cloudProjectId: this.projectId,
          region: this.region,
          zone: this.zone,
          machineType: this.machineType,
          runnerToken: this.token,
        };
      },
      result({ data }) {
        this.provisioningSteps = data.project.runnerCloudProvisioning?.provisioningSteps;
        this.setupBashScript = data.project.runnerCloudProvisioning?.projectSetupShellScript;
      },
      error(error) {
        captureException({ error, component: this.$options.name });
      },
      skip() {
        return !this.projectPath || this.invalidFields.length > 0;
      },
    },
  },
  computed: {
    isRunnerOnline() {
      return this.runner?.status === STATUS_ONLINE;
    },
    tokenMessage() {
      if (this.token) {
        return s__(
          'Runners|The %{boldStart}runner authentication token%{boldEnd} %{token} displays here %{boldStart}for a short time only%{boldEnd}. After you register the runner, this token is stored in the %{codeStart}config.toml%{codeEnd} and cannot be accessed again from the UI.',
        );
      }
      return s__(
        'Runners|The %{boldStart}runner authentication token%{boldEnd} is no longer visible, it is stored in the %{codeStart}config.toml%{codeEnd} if you have registered the runner.',
      );
    },
    invalidFields() {
      return Object.keys(this.validations).filter((field) => {
        return this.validations[field] === false;
      });
    },
    bashInstructions() {
      return this.setupBashScript.length > 0 ? this.setupBashScript : '';
    },
    terraformScriptInstructions() {
      return this.provisioningSteps.length > 0 ? this.provisioningSteps[0].instructions : '';
    },
    terraformApplyInstructions() {
      return this.provisioningSteps.length > 0 ? this.provisioningSteps[1].instructions : '';
    },
    codeStyles() {
      return {
        height: '300px',
      };
    },
  },
  watch: {
    invalidFields() {
      if (this.invalidFields.length === 0) {
        this.showAlert = false;
      }
    },
  },
  methods: {
    showInstructions() {
      if (this.invalidFields.length > 0) {
        this.showAlert = true;
      } else {
        this.showAlert = false;
        this.showInstructionsModal = true;
      }
    },
    validateZone() {
      if (this.zone.length > 0) {
        this.validations.zone = true;
      } else {
        this.validations.zone = false;
      }
    },
    validateRegion() {
      if (this.region.length > 0) {
        this.validations.region = true;
      } else {
        this.validations.region = false;
      }
    },
    validateProjectId() {
      if (this.projectId.length > 0) {
        this.validations.projectId = true;
      } else {
        this.validations.projectId = false;
      }
    },
    goToFirstInvalidField() {
      if (this.invalidFields.length > 0) {
        this.$refs[this.invalidFields[0]].$el.focus();
      }
    },
  },
  cancelModalOptions: {
    text: __('Cancel'),
  },
};
</script>

<template>
  <div>
    <div class="gl-mb-2">
      <h1 class="gl-font-size-h1">{{ $options.i18n.heading }}</h1>
      <p>
        <gl-icon name="information-o" class="gl-text-blue-600!" />
        <gl-sprintf :message="tokenMessage">
          <template #token>
            <code data-testid="runner-token">{{ token }}</code>
            <clipboard-button
              :text="token"
              :title="__('Copy')"
              size="small"
              category="tertiary"
              class="gl-border-none!"
            />
          </template>
          <template #bold="{ content }">
            <span class="gl-font-weight-bold">{{ content }}</span>
          </template>
          <template #code="{ content }">
            <code>{{ content }}</code>
          </template>
        </gl-sprintf>
      </p>
      <p>{{ $options.i18n.headingDescription }}</p>
    </div>
    <hr />

    <!-- start: before you begin -->
    <div>
      <h2 class="gl-font-lg">{{ $options.i18n.beforeHeading }}</h2>
      <ul>
        <li>
          <gl-sprintf :message="$options.i18n.permissionsText">
            <template #link="{ content }">
              <gl-link :href="$options.links.permissionsLink" target="_blank">
                {{ content }}
                <gl-icon name="external-link" :aria-label="$options.i18n.externalLink" />
              </gl-link>
            </template>
          </gl-sprintf>
        </li>
        <li>
          <gl-sprintf :message="$options.i18n.billingLinkText">
            <template #link="{ content }">
              <gl-link :href="$options.links.billingLink" target="_blank">
                {{ content }}
                <gl-icon name="external-link" :aria-label="$options.i18n.externalLink" />
              </gl-link>
            </template>
          </gl-sprintf>
        </li>
        <li>
          <gl-sprintf :message="$options.i18n.preInstallText">
            <template #gcloudLink="{ content }">
              <gl-link :href="$options.links.gcloudLink" target="_blank">
                {{ content }}
                <gl-icon name="external-link" :aria-label="$options.i18n.externalLink" />
              </gl-link>
            </template>
            <template #terraformLink="{ content }">
              <gl-link :href="$options.links.terraformLink" target="_blank">
                {{ content }}
                <gl-icon name="external-link" :aria-label="$options.i18n.externalLink" />
              </gl-link>
            </template>
          </gl-sprintf>
        </li>
      </ul>
    </div>
    <hr />
    <!-- end: before you begin -->

    <!-- start: step one -->
    <div class="gl-pb-4">
      <h2 class="gl-font-lg">{{ $options.i18n.stepOneHeading }}</h2>
      <p>{{ $options.i18n.stepOneDescription }}</p>
    </div>

    <gl-form-group :label="$options.i18n.projectIdLabel" label-for="project-id">
      <template #description>
        <gl-sprintf :message="$options.i18n.projectIdDescription">
          <template #link="{ content }">
            <gl-link
              :href="$options.links.projectIdLink"
              target="_blank"
              data-testid="project-id-link"
            >
              {{ content }} <gl-icon name="external-link" />
            </gl-link>
          </template>
        </gl-sprintf>
      </template>
      <gl-form-input
        id="project-id"
        ref="projectId"
        v-model="projectId"
        type="text"
        data-testid="project-id-input"
        @input="validateProjectId"
      />
    </gl-form-group>
    <gl-form-group label-for="region-id">
      <template #label>
        <div>
          {{ $options.i18n.regionLabel }}
          <gl-icon id="region-popover" class="gl-ml-2" name="question-o" />
          <gl-popover triggers="hover" placement="top" target="region-popover">
            <template #default>
              <p>{{ $options.i18n.regionHelpText }}</p>
              <gl-sprintf :message="$options.i18n.learnMore">
                <template #link="{ content }">
                  <gl-link :href="$options.links.regionAndZonesLink" target="_blank">
                    {{ content }} <gl-icon name="external-link" />
                  </gl-link>
                </template>
              </gl-sprintf>
            </template>
          </gl-popover>
        </div>
      </template>
      <gl-form-input
        id="region-id"
        ref="region"
        v-model="region"
        data-testid="region-input"
        @input="validateRegion"
      />
    </gl-form-group>
    <gl-form-group label-for="zone-id">
      <template #label>
        <div>
          {{ $options.i18n.zoneLabel }}
          <gl-icon id="zone-popover" class="gl-ml-2" name="question-o" />
          <gl-popover triggers="hover" placement="top" target="zone-popover">
            <template #default>
              <p>{{ $options.i18n.zoneHelpText }}</p>
              <gl-sprintf :message="$options.i18n.machineTypeDescription">
                <template #link="{ content }">
                  <gl-link :href="$options.links.regionAndZonesLink" target="_blank">
                    {{ content }} <gl-icon name="external-link" />
                  </gl-link>
                </template>
              </gl-sprintf>
            </template>
          </gl-popover>
        </div>
      </template>
      <template #description>
        <gl-link :href="$options.links.zonesLink" target="_blank" data-testid="zone-link">
          {{ $options.i18n.zonesLinkText }}
          <gl-icon name="external-link" />
        </gl-link>
      </template>
      <gl-form-input
        id="zone-id"
        ref="zone"
        v-model="zone"
        data-testid="zone-input"
        @input="validateZone"
      />
    </gl-form-group>
    <gl-form-group label-for="machine-type-id">
      <template #label>
        <div>
          {{ $options.i18n.machineTypeLabel }}
          <gl-icon id="machine-type-popover" class="gl-ml-2" name="question-o" />
          <gl-popover triggers="hover" placement="top" target="machine-type-popover">
            <template #default>
              {{ $options.i18n.machineTypeHelpText }}
            </template>
          </gl-popover>
        </div>
      </template>
      <template #description>
        <gl-sprintf :message="$options.i18n.machineTypeDescription">
          <template #link="{ content }">
            <gl-link
              :href="$options.links.machineTypesLink"
              target="_blank"
              data-testid="machine-types-link"
            >
              {{ content }} <gl-icon name="external-link" />
            </gl-link>
          </template>
        </gl-sprintf>
      </template>
      <gl-form-input id="machine-type-id" v-model="machineType" data-testid="machine-type-input" />
    </gl-form-group>

    <hr />
    <!-- end: step one -->

    <!-- start: step two -->
    <div class="gl-pb-4">
      <h2 class="gl-font-lg">{{ $options.i18n.stepTwoHeading }}</h2>
      <p>{{ $options.i18n.stepTwoDescription }}</p>
    </div>
    <gl-alert
      v-if="showAlert"
      :primary-button-text="$options.i18n.invalidFormButton"
      :dismissible="false"
      variant="danger"
      class="gl-mb-4"
      @primaryAction="goToFirstInvalidField"
    >
      {{ $options.i18n.alertBody }}
    </gl-alert>
    <gl-button data-testid="show-instructions-button" @click="showInstructions">{{
      $options.i18n.runnerSetupBtnText
    }}</gl-button>
    <gl-modal
      v-model="showInstructionsModal"
      cancel-variant="light"
      size="md"
      :scrollable="true"
      modal-id="setup-instructions"
      :action-cancel="$options.cancelModalOptions"
      :title="s__('Runners|Setup instructions')"
    >
      <p>{{ $options.i18n.modal.subtitle }}</p>
      <strong>{{ $options.i18n.modal.step2_1Header }}</strong>
      <p>{{ $options.i18n.modal.step2_1Body }}</p>
      <p>{{ $options.i18n.modal.step2_1Substep1 }}</p>
      <div class="gl-display-flex gl-my-4">
        <pre
          class="gl-w-full gl-py-4 gl-display-flex gl-justify-content-space-between gl-m-0"
          data-testid="bash-instructions"
          :style="codeStyles"
          >{{ bashInstructions }}</pre
        >
      </div>

      <strong>{{ $options.i18n.modal.step2_2Header }}</strong>
      <p>{{ $options.i18n.modal.step2_2Body }}</p>
      <p>{{ $options.i18n.modal.step2_2Substep1 }}</p>
      <div class="gl-display-flex gl-my-4">
        <pre
          class="gl-w-full gl-py-4 gl-display-flex gl-justify-content-space-between gl-m-0"
          data-testid="terraform-script-instructions"
          :style="codeStyles"
          >{{ terraformScriptInstructions }}</pre
        >
      </div>
      <p>{{ $options.i18n.modal.step2_2Substep2 }}</p>
      <div class="gl-display-flex gl-my-4">
        <pre
          class="gl-w-full gl-py-4 gl-display-flex gl-justify-content-space-between gl-m-0"
          data-testid="terraform-apply-instructions"
          >{{ terraformApplyInstructions }}</pre
        >
      </div>
      <p>{{ $options.i18n.modal.step2_2Substep3 }}</p>
    </gl-modal>
    <hr />
    <!-- end: step two -->
  </div>
</template>
