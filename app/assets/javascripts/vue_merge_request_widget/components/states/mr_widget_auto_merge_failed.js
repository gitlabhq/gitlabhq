export default {
  name: 'MRWidgetAutoMergeFailed',
  props: {
    mr: { type: Object, required: true },
  },
  template: `
    <div class="mr-widget-body">
      <button
        class="btn btn-success btn-small"
        disabled="true"
        type="button">
        Merge
      </button>
      <span class="bold danger">
        This merge request failed to be merged automatically.
      </span>
      <div class="merge-error-text">
        {{mr.mergeError}}
      </div>
    </div>
  `,
};
