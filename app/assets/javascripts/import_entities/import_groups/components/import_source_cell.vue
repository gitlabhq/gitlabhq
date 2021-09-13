<script>
import { GlLink, GlSprintf, GlIcon } from '@gitlab/ui';
import { joinPaths } from '~/lib/utils/url_utility';
import { isFinished } from '../utils';

export default {
  components: {
    GlLink,
    GlSprintf,
    GlIcon,
  },
  props: {
    group: {
      type: Object,
      required: true,
    },
  },
  computed: {
    fullLastImportPath() {
      return this.group.last_import_target
        ? `${this.group.last_import_target.target_namespace}/${this.group.last_import_target.new_name}`
        : null;
    },
    absoluteLastImportPath() {
      return joinPaths(gon.relative_url_root || '/', this.fullLastImportPath);
    },
    isFinished() {
      return isFinished(this.group);
    },
  },
};
</script>

<template>
  <div>
    <gl-link
      :href="group.web_url"
      target="_blank"
      class="gl-display-inline-flex gl-align-items-center gl-h-7"
    >
      {{ group.full_path }} <gl-icon name="external-link" />
    </gl-link>
    <div v-if="isFinished && fullLastImportPath" class="gl-font-sm">
      <gl-sprintf :message="s__('BulkImport|Last imported to %{link}')">
        <template #link>
          <gl-link :href="absoluteLastImportPath" class="gl-font-sm" target="_blank">{{
            fullLastImportPath
          }}</gl-link>
        </template>
      </gl-sprintf>
    </div>
  </div>
</template>
