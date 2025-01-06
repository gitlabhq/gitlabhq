<script>
import { GlAlert, GlButton, GlModal, GlModalDirective, GlSprintf } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import csrf from '~/lib/utils/csrf';
import TopicSelect from './topic_select.vue';

const formId = 'merge-topics-form';

export default {
  components: {
    GlAlert,
    GlButton,
    GlModal,
    GlSprintf,
    TopicSelect,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  inject: ['path'],
  data() {
    return {
      sourceTopic: {},
      targetTopic: {},
    };
  },
  computed: {
    sourceTopicId() {
      return getIdFromGraphQLId(this.sourceTopic?.id);
    },
    targetTopicId() {
      return getIdFromGraphQLId(this.targetTopic?.id);
    },
    validSelectedTopics() {
      return (
        Object.keys(this.sourceTopic).length &&
        Object.keys(this.targetTopic).length &&
        this.sourceTopic !== this.targetTopic
      );
    },
    actionPrimary() {
      return {
        text: __('Merge'),
        attributes: {
          variant: 'danger',
          disabled: !this.validSelectedTopics,
          type: 'submit',
          form: formId,
        },
      };
    },
  },
  methods: {
    selectSourceTopic(topic) {
      this.sourceTopic = topic;
    },
    selectTargetTopic(topic) {
      this.targetTopic = topic;
    },
  },
  i18n: {
    title: s__('MergeTopics|Merge topics'),
    body: s__(
      'MergeTopics|Move all assigned projects from the source topic to the target topic and remove the source topic.',
    ),
    sourceTopic: s__('MergeTopics|Source topic'),
    targetTopic: s__('MergeTopics|Target topic'),
    warningTitle: s__('MergeTopics|Merging topics will cause the following:'),
    warningBody: s__('MergeTopics|This action cannot be undone.'),
    warningRemoveTopic: s__('MergeTopics|%{sourceTopic} will be removed'),
    warningMoveProjects: s__('MergeTopics|All assigned projects will be moved to %{targetTopic}'),
  },
  formId,
  modal: {
    id: 'merge-topics',
    actionSecondary: {
      text: __('Cancel'),
      attributes: {
        variant: 'default',
      },
    },
  },
  csrf,
};
</script>
<template>
  <div>
    <gl-button v-gl-modal="$options.modal.id" category="secondary">{{
      $options.i18n.title
    }}</gl-button>
    <gl-modal
      :title="$options.i18n.title"
      :action-primary="actionPrimary"
      :action-secondary="$options.modal.actionSecondary"
      :modal-id="$options.modal.id"
      size="sm"
    >
      <p>{{ $options.i18n.body }}</p>
      <topic-select
        :selected-topic="sourceTopic"
        :label-text="$options.i18n.sourceTopic"
        @click="selectSourceTopic"
      />
      <topic-select
        :selected-topic="targetTopic"
        :label-text="$options.i18n.targetTopic"
        @click="selectTargetTopic"
      />
      <gl-alert
        v-if="validSelectedTopics"
        :title="$options.i18n.warningTitle"
        :dismissible="false"
        variant="danger"
      >
        <ul>
          <li>
            <gl-sprintf :message="$options.i18n.warningRemoveTopic">
              <template #sourceTopic>
                <strong>{{ sourceTopic.name }}</strong>
              </template>
            </gl-sprintf>
          </li>
          <li>
            <gl-sprintf :message="$options.i18n.warningMoveProjects">
              <template #targetTopic>
                <strong>{{ targetTopic.name }}</strong>
              </template>
            </gl-sprintf>
          </li>
        </ul>
        {{ $options.i18n.warningBody }}
      </gl-alert>
      <form :id="$options.formId" method="post" :action="path">
        <input type="hidden" name="_method" value="post" />
        <input type="hidden" name="authenticity_token" :value="$options.csrf.token" />
        <input type="hidden" name="source_topic_id" :value="sourceTopicId" />
        <input type="hidden" name="target_topic_id" :value="targetTopicId" />
      </form>
    </gl-modal>
  </div>
</template>
