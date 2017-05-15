export default {
  name: 'MRWidgetCodeQuality',
  props: {
    mr: { type: Object, required: true },
  },
  data() {
    return {
      issues: [],
      loadFailed: false,
      loadingMetrics: true,
    };
  },
  computed: {
    shouldShowLoading() {
      return this.loadingMetrics && !this.loadFailed;
    },
    shouldShowCodeQuality() {
      return !this.loadingMetrics && !this.loadFailed;
    },
    shouldShowLoadFailure() {
      return !this.loadingMetricss && this.loadFailed;
    },
  },
  methods: { 
    loadMetrics() { 
      $.ajax({
        context: this,
        type: "get",
        url: this.mr.codeClimate.head,
        success: function(data) {
          this.issues = data;
          this.loadFailed = false;
          this.loadingMetrics = false;
        },
        fail: function() {
          this.loadFailed = true;
          this.loadingMetrics = false;
        }
      });
    }, 
  },
  mounted() {
    this.loadingMetrics = true;
    this.loadMetrics();
  },
  template: `
    <section class="mr-widget-code-quality well">
      <p
        v-if="shouldShowLoading"
        class="usage-info js-usage-info usage-info-loading">
        <i
          class="fa fa-spinner fa-spin usage-info-load-spinner"
          aria-hidden="true" />Loading codeclimate report.
      </p>
      <p
        v-if="shouldShowCodeQuality">
        Code Climate:
      </p>
      <p
        v-if="shouldShowLoadFailure">
        Failed to load codeclimate report.
      </p>
      <ul>
        <li v-for="issue in issues">
          <span>{{ issue.check_name }}</span>
          <span>{{ issue.location.path }}</span>

          <span v-if="issue.location.positions">
            <span>{{ issue.location.positions }}</span>
          </span>

          <span v-if="issue.location.lines">
            <span>{{ issue.location.lines }}</span>
          </span>
        </li>
      </ul>
    </section>
  `,
};
