export default {
  name: 'MRWidgetMergeHelp',
  props: {
    missingBranch: { type: String, required: false, default: '' },
  },
  template: `
    <section class="mr-widget-help">
      <template
        v-if="missingBranch">
        If the {{missingBranch}} branch exists in your local repository,
          <a
            data-toggle="modal"
            href="#modal_merge_info">
            merge locally instead</a>.
      </template>
      <template v-else>
        <a
          data-toggle="modal"
          href="#modal_merge_info">
          Merge locally instead
        </a>
      </template>
    </section>
  `,
};
