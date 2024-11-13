<script>
import { GlButton, GlFormInput, GlLink, GlSprintf, GlIcon } from '@gitlab/ui';
import { GlBreakpointInstance } from '@gitlab/ui/dist/utils';
import GoogleCloudFieldGroup from '~/ci/runner/components/registration/google_cloud_field_group.vue';
import GoogleCloudLearnMoreLink from '~/ci/runner/components/registration/google_cloud_learn_more_link.vue';
import HelpPopover from '~/vue_shared/components/help_popover.vue';

const GC_IMAGE_TYPE_PATTERN = /^[a-z]+(_[a-z]+)*$/;
const GC_MACHINE_TYPE_PATTERN = /^[a-z]([-a-z0-9]*[a-z0-9])?$/;
const GC_NODE_COUNT_PATTERN = /\d+$/;
const GC_NAME_PATTERN = /^[a-z][a-z0-9-]{4,28}[a-z0-9]$/;

export default {
  name: 'GkeNodePool',
  formElementClasses: 'gl-mr-3 gl-mb-3 gl-basis-1/3 gl-shrink-0 gl-flex-grow-0',
  GC_IMAGE_TYPE_PATTERN,
  GC_MACHINE_TYPE_PATTERN,
  GC_NODE_COUNT_PATTERN,
  GC_NAME_PATTERN,
  components: {
    GoogleCloudFieldGroup,
    GoogleCloudLearnMoreLink,
    GlButton,
    GlFormInput,
    GlIcon,
    GlLink,
    GlSprintf,
    HelpPopover,
  },
  props: {
    nodePool: {
      type: Object,
      required: false,
      default: null,
    },
    uniqueIdentifier: {
      type: Number,
      required: false,
      default: 0,
    },
    showRemoveButton: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      imageType: this.nodePool?.imageType || null,
      machineType: this.nodePool?.machineType || null,
      nodeCount: this.nodePool?.nodeCount || null,
      nodePoolName: null,
      nodePoolLabels: [
        {
          key: '',
          value: '',
        },
      ],
    };
  },
  computed: {
    isMobile() {
      return ['sm', 'xs'].includes(GlBreakpointInstance.getBreakpointSize());
    },
    removeButtonCategory() {
      return this.isMobile ? 'secondary' : 'tertiary';
    },
    filteredNodePoolLabels() {
      return this.nodePoolLabels.filter(({ key }) => key !== '');
    },
  },
  methods: {
    canRemove(index) {
      return index < this.nodePoolLabels.length - 1;
    },
    updateNodePool() {
      this.$emit('update-node-pool', {
        nodePool: {
          imageType: this.imageType,
          machineType: this.machineType,
          nodeCount: this.nodeCount,
          nodePoolName: this.nodePoolName,
          nodePoolLabels: this.filteredNodePoolLabels,
        },
        uniqueIdentifier: this.uniqueIdentifier,
      });
    },
    addEmptyVariable() {
      const lastVar = this.nodePoolLabels[this.nodePoolLabels.length - 1];
      if (lastVar?.key === '' && lastVar?.value === '') {
        return;
      }

      this.updateNodePool();

      this.nodePoolLabels.push({
        key: '',
        value: '',
      });
    },
    removeVariable(index) {
      this.nodePoolLabels.splice(index, 1);
    },
    removeNodePool() {
      this.$emit('remove-node-pool', { uniqueIdentifier: this.uniqueIdentifier });
    },
  },
  links: {
    imageTypes: 'https://cloud.google.com/kubernetes-engine/docs/concepts/node-images',
    machineTypes: 'https://cloud.google.com/compute/docs/machine-resource',
    n2dMachineTypesLink:
      'https://cloud.google.com/compute/docs/general-purpose-machines#n2d_machine_types',
    nodeCount: 'https://cloud.google.com/kubernetes-engine/docs/concepts/plan-node-sizes',
    machineTypesLink: 'https://cloud.google.com/compute/docs/machine-resource',
  },
};
</script>
<template>
  <div data-testid="node-pool">
    <google-cloud-field-group
      ref="nodePoolName"
      v-model="nodePoolName"
      name="nodePoolName"
      :invalid-feedback-if-empty="s__('Runners|Node pool name is required.')"
      :invalid-feedback-if-malformed="s__('Runners|Node pool name must have the right format.')"
      :regexp="$options.GC_NAME_PATTERN"
      data-testid="node-pool-name-input"
      @change="updateNodePool"
    >
      <template #label>
        <div>
          {{ s__('Runners|Node pool name') }}
          <help-popover :aria-label="s__('Runners|Node pool name help')">
            <p>
              {{ s__('Runners|The name of node pool') }}
            </p>
          </help-popover>
        </div>
      </template>
      <template #description>
        <gl-sprintf :message="s__('Runners|Must have the format %{format}. Example: %{example}.')">
          <!-- eslint-disable @gitlab/vue-require-i18n-strings -->
          <template #example>
            <code>my-node-pool-191923</code>
          </template>
          <!-- eslint-enable @gitlab/vue-require-i18n-strings -->
        </gl-sprintf>
      </template>
    </google-cloud-field-group>
    <google-cloud-field-group
      ref="nodeCount"
      v-model="nodeCount"
      name="nodeCount"
      :invalid-feedback-if-empty="s__('Runners|Node count is required.')"
      :invalid-feedback-if-malformed="s__('Runners|Node count must have the right format.')"
      :regexp="$options.GC_NODE_COUNT_PATTERN"
      data-testid="node-count-input"
      @change="updateNodePool"
    >
      <template #label>
        <div>
          {{ s__('Runners|Node count') }}
          <help-popover :aria-label="s__('Runners|Node count help')">
            <p>
              {{
                s__('Runners|Plan the node count size to ensure you can accomodate your workload')
              }}
            </p>
            <google-cloud-learn-more-link :href="$options.links.nodeCount" />
          </help-popover>
        </div>
      </template>
    </google-cloud-field-group>
    <google-cloud-field-group
      ref="imageType"
      v-model="imageType"
      name="imageType"
      :invalid-feedback-if-empty="s__('Runners|Image Type is required.')"
      :invalid-feedback-if-malformed="s__('Runners|Image Type must have the right format.')"
      :regexp="$options.GC_IMAGE_TYPE_PATTERN"
      data-testid="image-type-input"
      @change="updateNodePool"
    >
      <template #label>
        <div>
          {{ s__('Runners|Image Type') }}
          <help-popover :aria-label="s__('Runners|Image Type help')">
            <p>
              {{ s__('Runners|Specific Image for the Nodes in the Node Pool to use') }}
            </p>
            <google-cloud-learn-more-link :href="$options.links.imageTypes" />
          </help-popover>
        </div>
      </template>
      <template #description>
        <gl-sprintf :message="s__('Runners|Must have the format %{format}. Example: %{example}.')">
          <!-- eslint-disable @gitlab/vue-require-i18n-strings -->
          <template #format>
            <code>&lt;name&gt;_&lt;type(optional)&gt;</code>
          </template>
          <template #example>
            <code>ubuntu_containerd</code>
          </template>
          <!-- eslint-enable @gitlab/vue-require-i18n-strings -->
        </gl-sprintf>
      </template>
    </google-cloud-field-group>
    <google-cloud-field-group
      ref="machineType"
      v-model="machineType"
      name="machineType"
      :invalid-feedback-if-empty="s__('Runners|Machine type is required.')"
      :invalid-feedback-if-malformed="s__('Runners|Machine type must have the right format.')"
      :regexp="$options.GC_MACHINE_TYPE_PATTERN"
      data-testid="machine-type-input"
      @change="updateNodePool"
    >
      <template #label>
        <div>
          {{ s__('Runners|Machine type') }}
          <help-popover :aria-label="s__('Runners|Machine type help')">
            <p>
              {{
                s__(
                  'Runners|Machine type with preset amounts of virtual machines processors (vCPUs) and memory',
                )
              }}
            </p>
            <google-cloud-learn-more-link :href="$options.links.machineTypesLink" />
          </help-popover>
        </div>
      </template>
      <template #description>
        <gl-sprintf
          :message="
            s__(
              'Runners|For most CI/CD jobs, use a %{linkStart}N2D standard machine type%{linkEnd}. Must have the format %{format}. Example: %{example}.',
            )
          "
        >
          <template #link="{ content }">
            <gl-link
              :href="$options.links.n2dMachineTypesLink"
              target="_blank"
              data-testid="machine-types-link"
            >
              {{ content }}
              <gl-icon name="external-link" :aria-label="__('(external link)')" />
            </gl-link>
          </template>
          <!-- eslint-disable @gitlab/vue-require-i18n-strings -->
          <template #format>
            <code>&lt;series&gt;-&lt;type&gt;</code>
          </template>
          <template #example>
            <code>n2d-standard-2</code>
          </template>
          <!-- eslint-enable @gitlab/vue-require-i18n-strings -->
        </gl-sprintf>
      </template>
    </google-cloud-field-group>
    <h4 class="gl-heading-4">{{ s__('Runners|Node pool labels') }}</h4>
    <!--start: Node pool labels -->
    <div
      v-for="(nodePoolLabel, index) in nodePoolLabels"
      :key="index"
      class="gl-mb-3 gl-pb-2"
      data-testid="node-pool-label-row-container"
    >
      <div class="gl-flex gl-flex-col gl-items-stretch md:gl-flex-row">
        <gl-form-input
          v-model="nodePoolLabel.key"
          :class="$options.formElementClasses"
          :placeholder="s__('Runners|Node pool label key')"
          data-testid="node-pool-label-key-field"
          @change="addEmptyVariable"
        />
        <gl-form-input
          v-model="nodePoolLabel.value"
          :class="$options.formElementClasses"
          :placeholder="s__('Runners|Node pool label value')"
          data-testid="node-pool-label-value-field"
        />
        <template v-if="nodePoolLabels.length > 1">
          <gl-button
            v-if="canRemove(index)"
            class="gl-mb-3 md:gl-ml-3"
            data-testid="remove-node-pool-label"
            :category="removeButtonCategory"
            :aria-label="s__('Runners|Remove Node pool label')"
            @click="removeVariable(index)"
          >
            <gl-icon class="!gl-mr-0" name="remove" />
            <span class="gl-ml-2 md:gl-hidden">{{ s__('Runners|Remove Node pool label') }}</span>
          </gl-button>
          <gl-button
            v-else
            class="gl-invisible gl-mb-3 gl-hidden md:gl-ml-3 md:gl-block"
            icon="remove"
            :aria-label="s__('Runners|Remove Node pool label')"
          />
        </template>
      </div>
    </div>
    <div class="gl-flex">
      <div class="gl-invisible gl-grow"></div>
      <gl-button
        v-if="showRemoveButton"
        class="gl-mt-2"
        data-testid="remove-node-pool-button"
        variant="danger"
        @click="removeNodePool"
      >
        {{ s__('Runners|Remove Node pool') }}
      </gl-button>
    </div>
    <hr />
    <!--end: Node pool labels-->
  </div>
</template>
