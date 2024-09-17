<script>
import { GlLabel } from '@gitlab/ui';
import { isScopedLabel } from '~/lib/utils/common_utils';
import { joinPaths } from '~/lib/utils/url_utility';
import { extractGroupOrProject } from '../../utils/common';

export default {
  name: 'LabelPresenter',
  components: {
    GlLabel,
  },
  props: {
    data: {
      required: true,
      type: Object,
    },
  },
  computed: {
    isScopedLabel() {
      return isScopedLabel({ title: this.data.title });
    },
    labelUrl() {
      const { group, project } = extractGroupOrProject();

      return joinPaths(
        window.location.origin,
        gon.relative_url_root,
        project || `groups/${group}`,
        `/-/issues?label=${encodeURIComponent(this.data.title)}`,
      );
    },
  },
};
</script>
<template>
  <gl-label
    :scoped="isScopedLabel"
    :background-color="data.color"
    :title="data.title"
    :target="labelUrl"
  />
</template>
