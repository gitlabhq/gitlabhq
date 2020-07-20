<script>
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { mapGetters } from 'vuex';
import { s__ } from '~/locale';
import { GlFormGroup, GlFormCheckbox, GlFormRadio } from '@gitlab/ui';

const commentDetailOptions = [
  {
    value: 'standard',
    label: s__('Integrations|Standard'),
    help: s__('Integrations|Includes commit title and branch'),
  },
  {
    value: 'all_details',
    label: s__('Integrations|All details'),
    help: s__(
      'Integrations|Includes Standard plus entire commit message, commit hash, and issue IDs',
    ),
  },
];

export default {
  name: 'JiraTriggerFields',
  components: {
    GlFormGroup,
    GlFormCheckbox,
    GlFormRadio,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    initialTriggerCommit: {
      type: Boolean,
      required: true,
    },
    initialTriggerMergeRequest: {
      type: Boolean,
      required: true,
    },
    initialEnableComments: {
      type: Boolean,
      required: true,
    },
    initialCommentDetail: {
      type: String,
      required: false,
      default: 'standard',
    },
  },
  data() {
    return {
      triggerCommit: this.initialTriggerCommit,
      triggerMergeRequest: this.initialTriggerMergeRequest,
      enableComments: this.initialEnableComments,
      commentDetail: this.initialCommentDetail,
      commentDetailOptions,
    };
  },
  computed: {
    ...mapGetters(['isInheriting']),
    showEnableComments() {
      return this.triggerCommit || this.triggerMergeRequest;
    },
  },
};
</script>

<template>
  <div v-if="glFeatures.integrationFormRefactor">
    <gl-form-group
      :label="__('Trigger')"
      label-for="service[trigger]"
      :description="
        s__(
          'Integrations|When a Jira issue is mentioned in a commit or merge request a remote link and comment (if enabled) will be created.',
        )
      "
    >
      <input name="service[commit_events]" type="hidden" :value="triggerCommit || false" />
      <gl-form-checkbox v-model="triggerCommit" :disabled="isInheriting">
        {{ __('Commit') }}
      </gl-form-checkbox>

      <input
        name="service[merge_requests_events]"
        type="hidden"
        :value="triggerMergeRequest || false"
      />
      <gl-form-checkbox v-model="triggerMergeRequest" :disabled="isInheriting">
        {{ __('Merge request') }}
      </gl-form-checkbox>
    </gl-form-group>

    <gl-form-group
      v-show="showEnableComments"
      :label="s__('Integrations|Comment settings:')"
      data-testid="comment-settings"
    >
      <input
        name="service[comment_on_event_enabled]"
        type="hidden"
        :value="enableComments || false"
      />
      <gl-form-checkbox v-model="enableComments" :disabled="isInheriting">
        {{ s__('Integrations|Enable comments') }}
      </gl-form-checkbox>
    </gl-form-group>

    <gl-form-group
      v-show="showEnableComments && enableComments"
      :label="s__('Integrations|Comment detail:')"
      data-testid="comment-detail"
    >
      <input
        v-if="isInheriting"
        name="service[comment_detail]"
        type="hidden"
        :value="commentDetail"
      />
      <gl-form-radio
        v-for="commentDetailOption in commentDetailOptions"
        :key="commentDetailOption.value"
        v-model="commentDetail"
        :value="commentDetailOption.value"
        :disabled="isInheriting"
      >
        {{ commentDetailOption.label }}
        <template #help>
          {{ commentDetailOption.help }}
        </template>
      </gl-form-radio>
    </gl-form-group>
  </div>

  <div v-else class="form-group row pt-2" role="group">
    <label for="service[trigger]" class="col-form-label col-sm-2 pt-0">{{ __('Trigger') }}</label>
    <div class="col-sm-10">
      <label class="weight-normal mb-2">
        {{
          s__(
            'Integrations|When a Jira issue is mentioned in a commit or merge request a remote link and comment (if enabled) will be created.',
          )
        }}
      </label>

      <input name="service[commit_events]" type="hidden" :value="triggerCommit || false" />
      <gl-form-checkbox v-model="triggerCommit" :disabled="isInheriting">
        {{ __('Commit') }}
      </gl-form-checkbox>

      <input
        name="service[merge_requests_events]"
        type="hidden"
        :value="triggerMergeRequest || false"
      />
      <gl-form-checkbox v-model="triggerMergeRequest" :disabled="isInheriting">
        {{ __('Merge request') }}
      </gl-form-checkbox>

      <div
        v-show="triggerCommit || triggerMergeRequest"
        class="mt-4"
        data-testid="comment-settings"
      >
        <label>
          {{ s__('Integrations|Comment settings:') }}
        </label>
        <input
          name="service[comment_on_event_enabled]"
          type="hidden"
          :value="enableComments || false"
        />
        <gl-form-checkbox v-model="enableComments" :disabled="isInheriting">
          {{ s__('Integrations|Enable comments') }}
        </gl-form-checkbox>

        <div v-show="enableComments" class="mt-4" data-testid="comment-detail">
          <label>
            {{ s__('Integrations|Comment detail:') }}
          </label>
          <input
            v-if="isInheriting"
            name="service[comment_detail]"
            type="hidden"
            :value="commentDetail"
          />
          <gl-form-radio
            v-for="commentDetailOption in commentDetailOptions"
            :key="commentDetailOption.value"
            v-model="commentDetail"
            :value="commentDetailOption.value"
            :disabled="isInheriting"
          >
            {{ commentDetailOption.label }}
            <template #help>
              {{ commentDetailOption.help }}
            </template>
          </gl-form-radio>
        </div>
      </div>
    </div>
  </div>
</template>
