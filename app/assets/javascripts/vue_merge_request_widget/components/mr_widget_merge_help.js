export default {
  name: 'MRWidgetMergeHelp',
  props: {
    missingBranch: { type: String, required: false, default: '' },
  },
  template: `
    <section class="mr-widget-help">
      <template
        v-if="missingBranch">
        If the {{missingBranch}} branch exists in your local repository, you
      </template>
      <template v-else>
        You
      </template>
      can merge this merge request manually using the
      <a
        data-toggle="modal"
        href="#modal_merge_info">
        command line
      </a>
    </section>
  `,
};
