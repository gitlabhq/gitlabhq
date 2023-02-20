<script>
import { GlButton, GlLink, GlModal, GlModalDirective } from '@gitlab/ui';
import csrf from '~/lib/utils/csrf';
import { s__ } from '~/locale';

export default {
  components: {
    GlButton,
    GlLink,
    GlModal,
  },
  PRUNE_UNREACHABLE_OBJECTS_MODAL_ID: 'prune-objects-modal',
  MODAL_ACTION_PRIMARY: {
    text: s__('UpdateProject|Prune'),
    attributes: [{ variant: 'danger' }],
  },
  MODAL_ACTION_CANCEL: {
    text: s__('UpdateProject|Cancel'),
  },
  directives: {
    GlModal: GlModalDirective,
  },
  props: {
    pruneObjectsPath: {
      type: String,
      required: true,
    },
    pruneObjectsDocPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    csrfToken() {
      return csrf.token;
    },
  },
  methods: {
    submitForm() {
      this.$refs.form.submit();
    },
  },
};
</script>

<template>
  <form ref="form" :action="pruneObjectsPath" method="post">
    <input :value="csrfToken" type="hidden" name="authenticity_token" />
    <input value="true" type="hidden" name="prune" />
    <gl-modal
      :modal-id="$options.PRUNE_UNREACHABLE_OBJECTS_MODAL_ID"
      :title="s__('UpdateProject|Are you sure you want to prune unreachable objects?')"
      :action-primary="$options.MODAL_ACTION_PRIMARY"
      :action-cancel="$options.MODAL_ACTION_CANCEL"
      size="sm"
      :no-focus-on-show="true"
      @ok="submitForm"
    >
      <p>
        {{ s__('UpdateProject|Pruning unreachable objects can lead to repository corruption.') }}
        <gl-link :href="pruneObjectsDocPath" target="_blank">
          {{ s__('UpdateProject|Learn more.') }}
        </gl-link>
        {{ s__('UpdateProject|Are you sure you want to prune?') }}
      </p>
    </gl-modal>
    <gl-button
      v-gl-modal="$options.PRUNE_UNREACHABLE_OBJECTS_MODAL_ID"
      category="primary"
      variant="danger"
    >
      {{ s__('UpdateProject|Prune unreachable objects') }}
    </gl-button>
  </form>
</template>
