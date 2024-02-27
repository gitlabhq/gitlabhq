<script>
import {
  GlButton,
  GlFormInput,
  GlFormGroup,
  GlLink,
  GlIcon,
  GlPopover,
  GlSprintf,
} from '@gitlab/ui';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_CI_RUNNER } from '~/graphql_shared/constants';
import runnerForRegistrationQuery from '../../graphql/register/runner_for_registration.query.graphql';
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
  },
  links: {
    projectIdLink:
      'https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects',
    regionAndZonesLink: 'https://cloud.google.com/compute/docs/regions-zones',
    zonesLink: 'https://console.cloud.google.com/compute/zones?pli=1',
    machineTypesLink:
      'https://cloud.google.com/compute/docs/general-purpose-machines#n2d_machine_types',
  },
  components: {
    ClipboardButton,
    GlButton,
    GlFormInput,
    GlFormGroup,
    GlIcon,
    GlLink,
    GlPopover,
    GlSprintf,
  },
  props: {
    runnerId: {
      type: String,
      required: true,
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
        v-model="projectId"
        type="text"
        data-testid="project-id-input"
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
      <gl-form-input id="region-id" v-model="region" data-testid="region-input" />
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
      <gl-form-input id="zone-id" v-model="zone" data-testid="zone-input" />
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
    <gl-button>{{ $options.i18n.runnerSetupBtnText }}</gl-button>

    <hr />
    <!-- end: step two -->
  </div>
</template>
