<script>
import { GlModal, GlSprintf } from '@gitlab/ui';
import { s__, __ } from '~/locale';

export default {
  name: 'RevokeReassignmentModal',
  components: {
    GlModal,
    GlSprintf,
  },
  props: {
    visible: {
      type: Boolean,
      required: false,
      default: false,
    },
    sourceUser: {
      type: Object,
      required: false,
      default: null,
    },
  },
  emits: ['primary', 'hidden'],
  computed: {
    sourceUserName() {
      return (
        this.sourceUser?.sourceName ||
        this.sourceUser?.sourceUsername ||
        this.sourceUser?.sourceHostname
      );
    },
  },
  primaryAction: {
    text: s__('UserMapping|Revoke reassignment'),
    attributes: { variant: 'danger' },
  },
  cancelAction: {
    text: __('Cancel'),
  },
};
</script>

<template>
  <gl-modal
    modal-id="revoke-reassignment-modal"
    :visible="visible"
    :title="s__('UserMapping|Revoke contribution reassignment?')"
    :action-primary="$options.primaryAction"
    :action-cancel="$options.cancelAction"
    @primary="$emit('primary')"
    @hidden="$emit('hidden')"
  >
    <p>
      <gl-sprintf
        :message="
          s__('UserMapping|If you revoke the reassignment of contributions from %{sourceUserName}:')
        "
      >
        <template #sourceUserName>
          <strong>{{ sourceUserName }}</strong>
        </template>
      </gl-sprintf>
    </p>
    <ul>
      <li>
        {{
          s__(
            'UserMapping|Future imports no longer automatically assign contributions from this user to you.',
          )
        }}
      </li>
      <li>
        {{
          s__(
            'UserMapping|A group owner can propose the same reassignment again, and contributions are only reassigned if you approve it.',
          )
        }}
      </li>
      <li>
        {{ s__('UserMapping|Contributions that were already reassigned to you are not removed.') }}
      </li>
    </ul>
  </gl-modal>
</template>
