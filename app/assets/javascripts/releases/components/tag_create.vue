<script>
import { GlButton, GlFormGroup, GlFormInput, GlFormTextarea } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapActions } from 'vuex';
import { uniqueId } from 'lodash';
import { __, s__ } from '~/locale';
import RefSelector from '~/ref/components/ref_selector.vue';

export default {
  components: {
    GlButton,
    GlFormGroup,
    GlFormInput,
    GlFormTextarea,
    RefSelector,
  },
  model: {
    prop: 'value',
    event: 'change',
  },
  props: {
    value: { type: String, required: true },
  },
  data() {
    return {
      nameId: uniqueId('tag-name-'),
      refId: uniqueId('ref-'),
      messageId: uniqueId('message-'),
    };
  },
  computed: {
    ...mapState('editNew', ['projectId', 'release', 'createFrom']),
  },
  methods: {
    ...mapActions('editNew', ['updateReleaseTagMessage', 'updateCreateFrom']),
  },
  i18n: {
    tagNameLabel: __('Tag name'),
    refLabel: __('Create from'),
    messageLabel: s__('CreateGitTag|Set tag message'),
    messagePlaceholder: s__(
      'CreateGitTag|Add a message to the tag. Leaving this blank creates a lightweight tag.',
    ),
    create: __('Save'),
    cancel: s__('Release|Select another tag'),
    refSelector: {
      noRefSelected: __('No source selected'),
      searchPlaceholder: __('Search branches, tags, and commits'),
      dropdownHeader: __('Select source'),
    },
  },
};
</script>
<template>
  <div class="gl-p-3" data-testid="create-from-field">
    <gl-form-group
      class="gl-mb-3"
      :label="$options.i18n.tagNameLabel"
      :label-for="nameId"
      label-sr-only
    >
      <gl-form-input :id="nameId" :value="value" autofocus @input="$emit('change', $event)" />
    </gl-form-group>
    <gl-form-group class="gl-mb-3" :label="$options.i18n.refLabel" :label-for="refId" label-sr-only>
      <ref-selector
        :id="refId"
        :project-id="projectId"
        :value="createFrom"
        :translations="$options.i18n.refSelector"
        @input="updateCreateFrom"
      />
    </gl-form-group>
    <gl-form-group
      class="gl-mb-3"
      :label="$options.i18n.messageLabel"
      :label-for="messageId"
      label-sr-only
    >
      <gl-form-textarea
        :id="messageId"
        :placeholder="$options.i18n.messagePlaceholder"
        :no-resize="false"
        :value="release.tagMessage"
        @input="updateReleaseTagMessage"
      />
    </gl-form-group>
    <gl-button class="gl-mr-3" variant="confirm" @click="$emit('create')">
      {{ $options.i18n.create }}
    </gl-button>
    <gl-button @click="$emit('cancel')">{{ $options.i18n.cancel }}</gl-button>
  </div>
</template>
