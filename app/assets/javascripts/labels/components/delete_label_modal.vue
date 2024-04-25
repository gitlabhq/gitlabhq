<script>
import { GlModal, GlSprintf, GlButton } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_NOT_FOUND } from '~/lib/utils/http_status';
import { createAlert } from '~/alert';
import { sprintf, __ } from '~/locale';
import eventHub, {
  EVENT_OPEN_DELETE_LABEL_MODAL,
  EVENT_DELETE_LABEL_MODAL_SUCCESS,
} from '../event_hub';

export default {
  components: {
    GlModal,
    GlSprintf,
    GlButton,
  },
  props: {
    remoteDestroy: {
      type: Boolean,
      required: false,
    },
  },
  data() {
    return {
      labelId: '',
      labelName: '',
      subjectName: '',
      destroyPath: '',
      modalId: uniqueId('modal-delete-label-'),
    };
  },
  computed: {
    title() {
      return sprintf(__('Delete label: %{labelName}'), { labelName: this.labelName });
    },
  },
  mounted() {
    eventHub.$on(
      EVENT_OPEN_DELETE_LABEL_MODAL,
      ({ labelId, labelName, subjectName, destroyPath }) => {
        this.labelId = labelId;
        this.labelName = labelName;
        this.subjectName = subjectName;
        this.destroyPath = destroyPath;
        this.openModal();
      },
    );
  },
  methods: {
    openModal() {
      this.$refs.modal.show();
    },
    closeModal() {
      this.$refs.modal.hide();
    },
    deleteThroughAjax(event) {
      event.preventDefault();
      event.stopPropagation();

      axios
        .delete(`${this.destroyPath}.js`)
        .then(() => {
          eventHub.$emit(EVENT_DELETE_LABEL_MODAL_SUCCESS, this.labelId);
        })
        .catch((error) => {
          if (error.response && error.response.status === HTTP_STATUS_NOT_FOUND) {
            createAlert({
              message: sprintf(__('Label %{labelName} was not found'), {
                labelName: this.labelName,
              }),
            });
          } else {
            Sentry.captureException(error);
            createAlert({
              message: sprintf(__('Could not delete the label %{labelName}. Please try again.'), {
                labelName: this.labelName,
              }),
            });
          }
        })
        .finally(() => {
          this.closeModal();
        });
    },
  },
};
</script>

<template>
  <gl-modal ref="modal" :modal-id="modalId" :title="title">
    <gl-sprintf
      v-if="subjectName"
      :message="
        __('%{labelName} will be permanently deleted from %{subjectName}. This cannot be undone.')
      "
    >
      <template #labelName>
        <strong>{{ labelName }}</strong>
      </template>
      <template #subjectName>{{ subjectName }}</template>
    </gl-sprintf>
    <gl-sprintf
      v-else
      :message="__('%{labelName} will be permanently deleted. This cannot be undone.')"
    >
      <template #labelName>
        <strong>{{ labelName }}</strong>
      </template>
    </gl-sprintf>
    <template #modal-footer>
      <gl-button category="secondary" @click="closeModal">{{ __('Cancel') }}</gl-button>
      <gl-button
        category="primary"
        variant="danger"
        :href="destroyPath"
        data-method="delete"
        data-testid="delete-button"
        v-on="remoteDestroy ? { click: deleteThroughAjax } : {}"
        >{{ __('Delete label') }}</gl-button
      >
    </template>
  </gl-modal>
</template>
