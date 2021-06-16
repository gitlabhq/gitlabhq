<script>
import {
  GlButton,
  GlForm,
  GlFormCheckbox,
  GlFormGroup,
  GlFormInputGroup,
  GlTooltipDirective,
} from '@gitlab/ui';
import createFlash, { FLASH_TYPES } from '~/flash';
import { __ } from '~/locale';
import { ACCESS_LEVEL_NOT_PROTECTED, ACCESS_LEVEL_REF_PROTECTED, PROJECT_TYPE } from '../constants';
import runnerUpdateMutation from '../graphql/runner_update.mutation.graphql';

const runnerToModel = (runner) => {
  const {
    id,
    description,
    maximumTimeout,
    accessLevel,
    active,
    locked,
    runUntagged,
    tagList = [],
  } = runner || {};

  return {
    id,
    description,
    maximumTimeout,
    accessLevel,
    active,
    locked,
    runUntagged,
    tagList: tagList.join(', '),
  };
};

export default {
  components: {
    GlButton,
    GlForm,
    GlFormCheckbox,
    GlFormGroup,
    GlFormInputGroup,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    runner: {
      type: Object,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      saving: false,
      model: runnerToModel(this.runner),
    };
  },
  computed: {
    canBeLockedToProject() {
      return this.runner?.runnerType === PROJECT_TYPE;
    },
    readonlyIpAddress() {
      return this.runner?.ipAddress;
    },
    updateMutationInput() {
      const { maximumTimeout, tagList } = this.model;

      return {
        ...this.model,
        maximumTimeout: maximumTimeout !== '' ? maximumTimeout : null,
        tagList: tagList
          .split(',')
          .map((tag) => tag.trim())
          .filter((tag) => Boolean(tag)),
      };
    },
  },
  watch: {
    runner(newVal, oldVal) {
      if (oldVal === null) {
        this.model = runnerToModel(newVal);
      }
    },
  },
  methods: {
    async onSubmit() {
      this.saving = true;

      try {
        const {
          data: {
            runnerUpdate: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: runnerUpdateMutation,
          variables: {
            input: this.updateMutationInput,
          },
        });

        if (errors?.length) {
          this.onError(new Error(errors[0]));
          return;
        }

        this.onSuccess();
      } catch (e) {
        this.onError(e);
      } finally {
        this.saving = false;
      }
    },
    onError(error) {
      const { message } = error;
      createFlash({ message });
    },
    onSuccess() {
      createFlash({ message: __('Changes saved.'), type: FLASH_TYPES.SUCCESS });
      this.model = runnerToModel(this.runner);
    },
  },
  ACCESS_LEVEL_NOT_PROTECTED,
  ACCESS_LEVEL_REF_PROTECTED,
};
</script>
<template>
  <gl-form @submit.prevent="onSubmit">
    <gl-form-checkbox
      v-model="model.active"
      data-testid="runner-field-paused"
      :value="false"
      :unchecked-value="true"
    >
      {{ __('Paused') }}
      <template #help>
        {{ __("Paused runners don't accept new jobs") }}
      </template>
    </gl-form-checkbox>

    <gl-form-checkbox
      v-model="model.accessLevel"
      data-testid="runner-field-protected"
      :value="$options.ACCESS_LEVEL_REF_PROTECTED"
      :unchecked-value="$options.ACCESS_LEVEL_NOT_PROTECTED"
    >
      {{ __('Protected') }}
      <template #help>
        {{ __('This runner will only run on pipelines triggered on protected branches') }}
      </template>
    </gl-form-checkbox>

    <gl-form-checkbox v-model="model.runUntagged" data-testid="runner-field-run-untagged">
      {{ __('Run untagged jobs') }}
      <template #help>
        {{ __('Indicates whether this runner can pick jobs without tags') }}
      </template>
    </gl-form-checkbox>

    <gl-form-checkbox
      v-model="model.locked"
      data-testid="runner-field-locked"
      :disabled="!canBeLockedToProject"
    >
      {{ __('Lock to current projects') }}
      <template #help>
        {{ __('When a runner is locked, it cannot be assigned to other projects') }}
      </template>
    </gl-form-checkbox>

    <gl-form-group :label="__('IP Address')" data-testid="runner-field-ip-address">
      <gl-form-input-group :value="readonlyIpAddress" readonly select-on-click>
        <template #append>
          <gl-button
            v-gl-tooltip.hover
            :title="__('Copy IP Address')"
            :aria-label="__('Copy IP Address')"
            :data-clipboard-text="readonlyIpAddress"
            icon="copy-to-clipboard"
            class="d-inline-flex"
          />
        </template>
      </gl-form-input-group>
    </gl-form-group>

    <gl-form-group :label="__('Description')" data-testid="runner-field-description">
      <gl-form-input-group v-model="model.description" />
    </gl-form-group>

    <gl-form-group
      data-testid="runner-field-max-timeout"
      :label="__('Maximum job timeout')"
      :description="
        s__(
          'Runners|Enter the number of seconds. This timeout takes precedence over lower timeouts set for the project.',
        )
      "
    >
      <gl-form-input-group v-model.number="model.maximumTimeout" type="number" />
    </gl-form-group>

    <gl-form-group
      data-testid="runner-field-tags"
      :label="__('Tags')"
      :description="
        __('You can set up jobs to only use runners with specific tags. Separate tags with commas.')
      "
    >
      <gl-form-input-group v-model="model.tagList" />
    </gl-form-group>

    <div class="form-actions">
      <gl-button
        type="submit"
        variant="confirm"
        class="js-no-auto-disable"
        :loading="saving || !runner"
      >
        {{ __('Save changes') }}
      </gl-button>
    </div>
  </gl-form>
</template>
