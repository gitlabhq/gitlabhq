<script>
import { GlAlert, GlButton, GlLink, GlIcon, GlModal, GlPopover, GlSprintf } from '@gitlab/ui';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import GoogleCloudFieldGroup from '~/ci/runner/components/registration/google_cloud_field_group.vue';
import { createAlert } from '~/alert';
import { s__, __ } from '~/locale';
import { fetchPolicies } from '~/lib/graphql';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_CI_RUNNER } from '~/graphql_shared/constants';
import runnerForRegistrationQuery from '../../graphql/register/runner_for_registration.query.graphql';
import provisionGoogleCloudRunnerGroup from '../../graphql/register/provision_google_cloud_runner_group.query.graphql';
import provisionGoogleCloudRunnerProject from '../../graphql/register/provision_google_cloud_runner_project.query.graphql';

import {
  I18N_FETCH_ERROR,
  STATUS_ONLINE,
  RUNNER_REGISTRATION_POLLING_INTERVAL_MS,
} from '../../constants';
import { captureException } from '../../sentry_utils';

const GC_PROJECT_PATTERN = /^[a-z][a-z0-9-]{4,28}[a-z0-9]$/; // https://cloud.google.com/resource-manager/reference/rest/v1/projects
const GC_REGION_PATTERN = /^[a-z]+-[a-z]+\d+$/;
const GC_ZONE_PATTERN = /^[a-z]+-[a-z]+\d+-[a-z]$/;
const GC_MACHINE_TYPE_PATTERN = /^[a-z]([-a-z0-9]*[a-z0-9])?$/;

export default {
  name: 'GoogleCloudRegistrationInstructions',
  GC_PROJECT_PATTERN,
  GC_REGION_PATTERN,
  GC_ZONE_PATTERN,
  GC_MACHINE_TYPE_PATTERN,
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
      'Runners|For most CI/CD jobs, use a %{linkStart}N2D standard machine type%{linkEnd}.',
    ),
    runnerSetupBtnText: s__('Runners|Setup instructions'),
    modal: {
      subtitle: s__(
        'Runners|These setup instructions use your specifications and follow the best practices for performance and security.',
      ),
      step2_1Header: s__('Runners|Step 1: Configure your Google Cloud project'),
      step2_1Body: s__(
        `Runners|If you haven't already configured your Google Cloud project, this step enables the required services and creates a service account with the required permissions. `,
      ),
      step2_1Substep1: s__(
        'Runners|Run the following on your command line. You might be prompted to sign in to Google.',
      ),
      step2_2Header: s__('Runners|Step 2: Install and register GitLab Runner'),
      step2_2Body: s__(
        'Runners|This step creates the required infrastructure in Google Cloud, installs GitLab Runner, and registers it to this GitLab project. ',
      ),
      step2_2Substep1: s__(
        'Runners|Use a text editor to create a %{codeStart}main.tf%{codeEnd} file with the following Terraform configuration.',
      ),
      step2_2Substep2: s__(
        'Runners|In the directory with that Terraform configuration file, run the following on your command line.',
      ),
      step2_2Substep3: s__(
        'Runners|After GitLab Runner is installed and registered, an autoscaling fleet of runners is available to execute your CI/CD jobs in Google Cloud.',
      ),
    },
    copyCommands: __('Copy commands'),
    emptyFieldsAlertMessage: s__(
      'Runners|To view the setup instructions, complete the previous form.',
    ),
    invalidFieldsAlertMessage: s__(
      'Runners|To view the setup instructions, make sure all form fields are completed and correct.',
    ),
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
    machineTypesLink: 'https://cloud.google.com/compute/docs/machine-resource',
    n2dMachineTypesLink:
      'https://cloud.google.com/compute/docs/general-purpose-machines#n2d_machine_types',
  },
  components: {
    ClipboardButton,
    GoogleCloudFieldGroup,
    GlAlert,
    GlButton,
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
      token: '',
      runner: null,
      showInstructionsModal: false,
      showInstructionsButtonVariant: 'default',

      cloudProjectId: null,
      region: null,
      zone: null,
      machineType: { state: true, value: 'n2d-standard-2' },

      provisioningSteps: [],
      setupBashScript: '',
      showAlert: false,
      group: null,
      project: null,
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
      fetchPolicy: fetchPolicies.NETWORK_ONLY,
      skip: true,
      manual: true,
      variables() {
        return {
          fullPath: this.projectPath,
          ...this.variables,
        };
      },
      result({ data, error }) {
        if (!error) {
          this.showAlert = false;
          this.provisioningSteps = data.project.runnerCloudProvisioning?.provisioningSteps;
          this.setupBashScript = data.project.runnerCloudProvisioning?.projectSetupShellScript;
        }
      },
      error(error) {
        this.handleError(error);
      },
    },
    group: {
      query: provisionGoogleCloudRunnerGroup,
      fetchPolicy: fetchPolicies.NETWORK_ONLY,
      skip: true,
      manual: true,
      variables() {
        return {
          fullPath: this.groupPath,
          ...this.variables,
        };
      },
      result({ data, error }) {
        if (!error) {
          this.showAlert = false;
          this.provisioningSteps = data.group.runnerCloudProvisioning?.provisioningSteps;
          this.setupBashScript = data.group.runnerCloudProvisioning?.projectSetupShellScript;
        }
      },
      error(error) {
        this.handleError(error);
      },
    },
  },
  computed: {
    variables() {
      return {
        runnerToken: this.token,
        cloudProjectId: this.cloudProjectId?.value,
        region: this.region?.value,
        zone: this.zone?.value,
        machineType: this.machineType?.value,
      };
    },
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
      return ['cloudProjectId', 'region', 'zone', 'machineType'].filter((field) => {
        return !this[field]?.state;
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
        maxHeight: '300px',
      };
    },
  },
  watch: {
    invalidFields() {
      if (this.invalidFields.length === 0) {
        this.showAlert = false;
        this.showInstructionsButtonVariant = 'confirm';
      } else {
        this.showInstructionsButtonVariant = 'default';
      }
    },
  },
  methods: {
    showInstructions() {
      if (this.invalidFields.length > 0) {
        this.showAlert = true;
      } else {
        if (this.projectPath) {
          this.$apollo.queries.project.start();
        } else {
          this.$apollo.queries.group.start();
        }
        this.showAlert = false;
        this.showInstructionsModal = true;
      }
    },

    goToFirstInvalidField() {
      if (this.invalidFields.length > 0) {
        this.$refs[this.invalidFields[0]].$el.querySelector('input').focus();
      }
    },
    handleError(error) {
      if (error.message.includes('GraphQL error')) {
        this.showAlert = true;
      }
      if (error.networkError) {
        captureException({ error, component: this.$options.name });
      }
    },
  },
  cancelModalOptions: {
    text: __('Close'),
  },
};
</script>

<template>
  <div>
    <div class="gl-mt-5">
      <h1 class="gl-heading-1">{{ $options.i18n.heading }}</h1>
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
      <h2 class="gl-heading-2">{{ $options.i18n.beforeHeading }}</h2>
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
    <h2 class="gl-heading-2">{{ $options.i18n.stepOneHeading }}</h2>
    <p>{{ $options.i18n.stepOneDescription }}</p>

    <google-cloud-field-group
      ref="cloudProjectId"
      v-model="cloudProjectId"
      name="cloudProjectId"
      :label="$options.i18n.projectIdLabel"
      :invalid-feedback-if-empty="s__('Runners|Project ID is required.')"
      :invalid-feedback-if-malformed="
        s__(
          'Runners|Project ID must be 6 to 30 lowercase letters, digits, or hyphens. It needs to start with a lowercase letter and end with a letter or number.',
        )
      "
      :regexp="$options.GC_PROJECT_PATTERN"
      data-testid="project-id-input"
    >
      <template #description>
        <gl-sprintf :message="$options.i18n.projectIdDescription">
          <template #link="{ content }">
            <gl-link
              :href="$options.links.projectIdLink"
              target="_blank"
              data-testid="project-id-link"
            >
              {{ content }}
              <gl-icon name="external-link" :aria-label="$options.i18n.externalLink" />
            </gl-link>
          </template>
        </gl-sprintf>
      </template>
    </google-cloud-field-group>

    <google-cloud-field-group
      ref="region"
      v-model="region"
      name="region"
      :invalid-feedback-if-empty="s__('Runners|Region is required.')"
      :invalid-feedback-if-malformed="
        s__('Runners|Region must have the correct format. Example: us-central1')
      "
      :regexp="$options.GC_REGION_PATTERN"
      data-testid="region-input"
    >
      <template #label>
        <div>
          {{ $options.i18n.regionLabel }}
          <gl-icon id="region-popover" name="question-o" class="gl-text-blue-600" />
          <gl-popover triggers="hover" placement="top" target="region-popover">
            <template #default>
              <p>{{ $options.i18n.regionHelpText }}</p>
              <gl-sprintf :message="$options.i18n.learnMore">
                <template #link="{ content }">
                  <gl-link :href="$options.links.regionAndZonesLink" target="_blank">
                    {{ content }}
                    <gl-icon name="external-link" :aria-label="$options.i18n.externalLink" />
                  </gl-link>
                </template>
              </gl-sprintf>
            </template>
          </gl-popover>
        </div>
      </template>
    </google-cloud-field-group>

    <google-cloud-field-group
      ref="zone"
      v-model="zone"
      name="zone"
      :invalid-feedback-if-empty="s__('Runners|Zone is required.')"
      :invalid-feedback-if-malformed="
        s__('Runners|Zone must have the correct format. Example: us-central1-a')
      "
      :regexp="$options.GC_ZONE_PATTERN"
      data-testid="zone-input"
    >
      <template #label>
        <div>
          {{ $options.i18n.zoneLabel }}
          <gl-icon id="zone-popover" name="question-o" class="gl-text-blue-600" />
          <gl-popover triggers="hover" placement="top" target="zone-popover">
            <template #default>
              <p>{{ $options.i18n.zoneHelpText }}</p>
              <gl-sprintf :message="$options.i18n.learnMore">
                <template #link="{ content }">
                  <gl-link :href="$options.links.regionAndZonesLink" target="_blank">
                    {{ content }}
                    <gl-icon name="external-link" :aria-label="$options.i18n.externalLink" />
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
          <gl-icon name="external-link" :aria-label="$options.i18n.externalLink" />
        </gl-link>
      </template>
    </google-cloud-field-group>

    <google-cloud-field-group
      ref="machineType"
      v-model="machineType"
      name="machineType"
      :invalid-feedback-if-empty="s__('Runners|Machine type is required.')"
      :invalid-feedback-if-malformed="
        s__(
          'Runners|Machine type must have the format `family-series-size`. Example: n2d-standard-2',
        )
      "
      :regexp="$options.GC_MACHINE_TYPE_PATTERN"
      data-testid="machine-type-input"
    >
      <template #label>
        <div>
          {{ $options.i18n.machineTypeLabel }}
          <gl-icon id="machine-type-popover" name="question-o" class="gl-text-blue-600" />
          <gl-popover triggers="hover" placement="top" target="machine-type-popover">
            <template #default>
              <p>{{ $options.i18n.machineTypeHelpText }}</p>
              <gl-sprintf :message="$options.i18n.learnMore">
                <template #link="{ content }">
                  <gl-link :href="$options.links.machineTypesLink" target="_blank">
                    {{ content }}
                    <gl-icon name="external-link" :aria-label="$options.i18n.externalLink" />
                  </gl-link>
                </template>
              </gl-sprintf>
            </template>
          </gl-popover>
        </div>
      </template>
      <template #description>
        <gl-sprintf :message="$options.i18n.machineTypeDescription">
          <template #link="{ content }">
            <gl-link
              :href="$options.links.n2dMachineTypesLink"
              target="_blank"
              data-testid="machine-types-link"
            >
              {{ content }}
              <gl-icon name="external-link" :aria-label="$options.i18n.externalLink" />
            </gl-link>
          </template>
        </gl-sprintf>
      </template>
    </google-cloud-field-group>

    <hr />
    <!-- end: step one -->

    <!-- start: step two -->
    <h2 class="gl-heading-2">{{ $options.i18n.stepTwoHeading }}</h2>
    <p>{{ $options.i18n.stepTwoDescription }}</p>
    <gl-alert
      v-if="showAlert"
      :primary-button-text="$options.i18n.invalidFormButton"
      :dismissible="false"
      variant="danger"
      class="gl-mb-4"
      @primaryAction="goToFirstInvalidField"
    >
      <template v-if="invalidFields.length > 0">
        {{ $options.i18n.emptyFieldsAlertMessage }}
      </template>
      <template v-else>
        {{ $options.i18n.invalidFieldsAlertMessage }}
      </template>
    </gl-alert>
    <gl-button
      data-testid="show-instructions-button"
      :variant="showInstructionsButtonVariant"
      category="secondary"
      @click="showInstructions"
      >{{ $options.i18n.runnerSetupBtnText }}</gl-button
    >
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
      <h3 class="gl-heading-4">{{ $options.i18n.modal.step2_1Header }}</h3>
      <p>{{ $options.i18n.modal.step2_1Body }}</p>
      <p>{{ $options.i18n.modal.step2_1Substep1 }}</p>
      <div class="gl-display-flex gl-align-items-flex-start">
        <pre class="gl-w-full gl-mb-5" data-testid="bash-instructions" :style="codeStyles">{{
          bashInstructions
        }}</pre>
      </div>

      <h3 class="gl-heading-4">{{ $options.i18n.modal.step2_2Header }}</h3>
      <p>{{ $options.i18n.modal.step2_2Body }}</p>
      <p>
        <gl-sprintf :message="$options.i18n.modal.step2_2Substep1">
          <template #code="{ content }">
            <code>{{ content }}</code>
          </template>
        </gl-sprintf>
      </p>
      <div class="gl-display-flex gl-align-items-flex-start">
        <pre
          class="gl-w-full gl-mb-5"
          data-testid="terraform-script-instructions"
          :style="codeStyles"
          >{{ terraformScriptInstructions }}</pre
        >
      </div>
      <p>{{ $options.i18n.modal.step2_2Substep2 }}</p>
      <div class="gl-display-flex gl-align-items-flex-start">
        <pre
          class="gl-w-full gl-mb-5"
          data-testid="terraform-apply-instructions"
          :style="codeStyles"
          >{{ terraformApplyInstructions }}</pre
        >
      </div>
      <p>{{ $options.i18n.modal.step2_2Substep3 }}</p>
    </gl-modal>
    <hr />
    <!-- end: step two -->
    <section v-if="isRunnerOnline">
      <h2 class="gl-heading-2">🎉 {{ s__("Runners|You've registered a new runner!") }}</h2>
      <p>
        {{ s__('Runners|Your runner is online and ready to run jobs.') }}
      </p>
    </section>
  </div>
</template>
