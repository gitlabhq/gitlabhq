<script>
import { GlButton, GlEmptyState, GlLink } from '@gitlab/ui';
import { mapState } from 'vuex';
import { createAlert } from '~/flash';
import { logError } from '~/lib/logger';
import axios from '~/lib/utils/axios_utils';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { ignoreWhilePending } from '~/lib/utils/ignore_while_pending';
import { s__, __ } from '~/locale';
import eventHub from '../../eventhub';

export const MSG_DESCRIPTION = s__('WebIDE|You are invited to experience the new Web IDE.');
export const MSG_BUTTON_TEXT = s__('WebIDE|Switch to new Web IDE');
export const MSG_LEARN_MORE = __('Learn more');
export const MSG_TITLE = s__('WebIDE|Ready for something new?');

export const MSG_CONFIRM = s__(
  'WebIDE|Are you sure you want to switch editors? You will lose any unsaved changes.',
);
export const MSG_ERROR_ALERT = s__(
  'WebIDE|Something went wrong while updating the user preferences. Please see developer console for details.',
);

export default {
  components: {
    GlButton,
    GlEmptyState,
    GlLink,
  },
  data() {
    return {
      loading: false,
    };
  },
  computed: {
    ...mapState(['switchEditorSvgPath', 'links', 'userPreferencesPath']),
  },
  methods: {
    async submitSwitch() {
      const confirmed = await confirmAction(MSG_CONFIRM, {
        primaryBtnText: __('Switch editors'),
        cancelBtnText: __('Cancel'),
      });

      if (!confirmed) {
        return;
      }

      try {
        await axios.put(this.userPreferencesPath, {
          user: { use_legacy_web_ide: false },
        });
      } catch (e) {
        // why: We do not want to translate console logs
        // eslint-disable-next-line @gitlab/require-i18n-strings
        logError('Error while updating user preferences', e);
        createAlert({
          message: MSG_ERROR_ALERT,
        });
        return;
      }

      eventHub.$emit('skip-beforeunload');
      window.location.reload();
    },
    // what: ignoreWhilePending prevents double confirmation boxes
    onSwitchClicked: ignoreWhilePending(async function onSwitchClicked() {
      this.loading = true;

      try {
        await this.submitSwitch();
      } finally {
        this.loading = false;
      }
    }),
  },
  MSG_TITLE,
  MSG_DESCRIPTION,
  MSG_BUTTON_TEXT,
  MSG_LEARN_MORE,
};
</script>

<template>
  <div class="gl-h-full gl-display-flex gl-flex-direction-column gl-justify-content-center">
    <gl-empty-state :svg-path="switchEditorSvgPath" :svg-height="150" :title="$options.MSG_TITLE">
      <template #description>
        <span>{{ $options.MSG_DESCRIPTION }}</span>
        <gl-link :href="links.newWebIDEHelpPagePath">{{ $options.MSG_LEARN_MORE }}</gl-link
        >.
      </template>
      <template #actions>
        <gl-button
          category="primary"
          variant="confirm"
          :loading="loading"
          @click="onSwitchClicked"
          >{{ $options.MSG_BUTTON_TEXT }}</gl-button
        >
      </template>
    </gl-empty-state>
  </div>
</template>
