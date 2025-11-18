<script>
import { GlForm, GlModal, GlFormInput, GlFormGroup } from '@gitlab/ui';
import csrf from '~/lib/utils/csrf';
import { __, s__, sprintf } from '~/locale';
import Tracking from '~/tracking';
import { getParameterByName } from '~/lib/utils/url_utility';
import {
  WIKI_RESTORE_VERSION_ACTION,
  WIKI_RESTORE_VERSION_LABEL,
  WIKI_RESTORE_VERSION_TRACKING_LABEL,
} from '../constants';

const trackingMixin = Tracking.mixin({
  label: WIKI_RESTORE_VERSION_TRACKING_LABEL,
});

export default {
  name: 'RestoreVersionModal',
  components: {
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlModal,
  },
  mixins: [trackingMixin],
  inject: {
    pageInfo: { default: null },
  },
  props: {
    modalId: {
      type: String,
      required: true,
    },
  },
  data() {
    const versionNumber = getParameterByName('version_number');
    const restoredFrom = versionNumber
      ? sprintf(s__('Wiki|v%{version}'), { version: versionNumber })
      : s__('Wiki|old version');

    return {
      restoredFrom,
      commitMessage: sprintf(s__('Wiki|Restored from %{from}'), { from: restoredFrom }),
    };
  },
  computed: {
    primaryAction() {
      return {
        text: this.$options.i18n.restoreText,
        attributes: {
          variant: 'confirm',
          type: 'submit',
          form: 'wiki-restore-version-form',
        },
      };
    },
    cancelAction() {
      return {
        text: this.$options.i18n.cancelText,
      };
    },
    csrfToken() {
      return csrf.token;
    },
  },
  methods: {
    async handleRestore(e) {
      e.preventDefault();

      if (e.type !== 'submit') {
        return;
      }

      this.track(WIKI_RESTORE_VERSION_ACTION, {
        label: WIKI_RESTORE_VERSION_LABEL,
        extra: {
          project_path: this.pageInfo.path,
          restored_from: this.restoredFrom,
        },
      });

      // Wait until form field values are refreshed
      await this.$nextTick();
      e.target.submit();
    },
  },
  i18n: {
    cancelText: __('Cancel'),
    restoreText: __('Restore'),
    restoreModalTitle: s__('Wiki|Restore this version'),
    commitMessageLabel: s__('Wiki|Commit message'),
    commitMessagePlaceholder: s__('Wiki|Enter commit message'),
  },
};
</script>

<template>
  <gl-modal
    size="sm"
    :modal-id="modalId"
    :title="s__('Wiki|Restore version modal')"
    :action-primary="primaryAction"
    :action-cancel="cancelAction"
    @primary="handleRestore"
  >
    <template #modal-title>
      <h3 class="gl-heading-4 !gl-m-0">
        {{ $options.i18n.restoreModalTitle }}
      </h3>
    </template>

    <gl-form
      id="wiki-restore-version-form"
      ref="form"
      :action="pageInfo.path"
      method="post"
      class="wiki-restore-version-form js-quick-submit"
      @submit="handleRestore"
    >
      <input type="hidden" name="_method" value="put" />
      <input type="hidden" name="authenticity_token" :value="csrfToken" />
      <input type="hidden" name="wiki[last_commit_sha]" :value="pageInfo.lastCommitSha" />
      <input type="hidden" name="wiki[title]" :value="pageInfo.title" />
      <input type="hidden" name="wiki[content]" :value="pageInfo.content" />
      <input type="hidden" name="wiki[format]" :value="pageInfo.format" />

      <gl-form-group
        :label="$options.i18n.commitMessageLabel"
        label-for="wiki-restore-version-commit-message"
      >
        <gl-form-input
          id="wiki-restore-version-commit-message"
          v-model="commitMessage"
          name="wiki[message]"
          type="text"
          class="form-control"
          :placeholder="$options.i18n.commitMessagePlaceholder"
          :required="true"
        />
      </gl-form-group>
    </gl-form>
  </gl-modal>
</template>
