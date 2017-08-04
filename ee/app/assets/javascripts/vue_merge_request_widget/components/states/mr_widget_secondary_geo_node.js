export default {
  props: {
    mr: {
      type: Object,
      required: true,
    },
  },
  template: `
    <div>
      <button type="button" class="btn btn-success btn-small" disabled="true">Merge</button>
      <span class="bold">
        Merge requests are read-only in a secondary Geo node.
      </span>
      <a
        :href="mr.geoSecondaryHelpPath"
        data-title="About this feature"
        data-toggle="tooltip"
        data-placement="bottom"
        target="_blank"
        rel="noopener noreferrer nofollow"
        data-container="body">
        <i class="fa fa-question-circle"></i>
      </a>
    </div>
  `,
};
