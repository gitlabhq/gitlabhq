<script>
import { GlSprintf, GlModal } from '@gitlab/ui';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { visitUrl } from '~/lib/utils/url_utility';
import { s__, __, sprintf } from '~/locale';
import eventHub from '../event_hub';

export default {
  primaryProps: {
    text: s__('Labels|Promote Label'),
    attributes: [{ variant: 'warning' }, { category: 'primary' }],
  },
  cancelProps: {
    text: __('Cancel'),
  },
  components: {
    GlModal,
    GlSprintf,
  },
  props: {
    url: {
      type: String,
      required: true,
    },
    labelTitle: {
      type: String,
      required: true,
    },
    labelColor: {
      type: String,
      required: true,
    },
    labelTextColor: {
      type: String,
      required: true,
    },
    groupName: {
      type: String,
      required: true,
    },
  },
  computed: {
    text() {
      return sprintf(
        s__(`Labels|Promoting %{labelTitle} will make it available for all projects inside %{groupName}.
        Existing project labels with the same title will be merged. If a group label with the same title exists,
        it will also be merged. This action cannot be reversed.`),
        {
          labelTitle: this.labelTitle,
          groupName: this.groupName,
        },
      );
    },
  },
  methods: {
    onSubmit() {
      eventHub.$emit('promoteLabelModal.requestStarted', this.url);
      return axios
        .post(this.url, { params: { format: 'json' } })
        .then((response) => {
          eventHub.$emit('promoteLabelModal.requestFinished', {
            labelUrl: this.url,
            successful: true,
          });
          visitUrl(response.data.url);
        })
        .catch((error) => {
          eventHub.$emit('promoteLabelModal.requestFinished', {
            labelUrl: this.url,
            successful: false,
          });
          createFlash({
            message: error,
          });
        });
    },
  },
};
</script>
<template>
  <gl-modal
    modal-id="promote-label-modal"
    :action-primary="$options.primaryProps"
    :action-cancel="$options.cancelProps"
    @primary="onSubmit"
  >
    <template #modal-title>
      <div class="modal-title-with-label">
        <gl-sprintf
          :message="
            s__(
              'Labels|%{spanStart}Promote label%{spanEnd} %{labelTitle} %{spanStart}to Group Label?%{spanEnd}',
            )
          "
        >
          <template #labelTitle>
            <span
              class="label color-label"
              :style="`background-color: ${labelColor}; color: ${labelTextColor};`"
            >
              {{ labelTitle }}
            </span>
          </template>
          <template #span="{ content }"
            ><span>{{ content }}</span></template
          >
        </gl-sprintf>
      </div>
    </template>
    {{ text }}
  </gl-modal>
</template>
