<script>
import { GlLabel } from '@gitlab/ui';
import { isScopedLabel } from '~/lib/utils/common_utils';
import { projectIssuesPath } from '~/lib/utils/path_helpers/issues';
import { issuesGroupPath } from '~/lib/utils/path_helpers/group';
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
    labelMarkdown() {
      if (this.isScopedLabel || /\W/.test(this.data.title)) return `~"${this.data.title}"`;
      return `~${this.data.title}`;
    },
    labelUrl() {
      const { group, project } = extractGroupOrProject();

      if (project) {
        return projectIssuesPath(project, { label: this.data.title });
      }

      return issuesGroupPath(group, { label: this.data.title });
    },
  },
};
</script>
<template>
  <gl-label
    data-reference-type="label"
    class="gfm gfm-label"
    :data-original="labelMarkdown"
    :scoped="isScopedLabel"
    :background-color="data.color"
    :title="data.title"
    :target="labelUrl"
  />
</template>
