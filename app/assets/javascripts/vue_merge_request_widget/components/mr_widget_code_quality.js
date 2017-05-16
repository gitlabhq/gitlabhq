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
      this.loadUrl(this.mr.codeClimate.head, function(data) { 
        this.headIssues = data

        this.loadUrl(this.mr.codeClimate.base, function(data) { 
          this.baseIssues = data;

          this.newIssues = this.headIssues.filter((item) => {
            return !this.baseIssues.find(function(element) { 
              return element.fingerprint == item.fingerprint;
            });
          });

          this.resolvedIssues = this.baseIssues.filter((item) => {
            return !this.headIssues.find(function(element) { 
              return element.fingerprint == item.fingerprint;
            });
          });

          console.log(this.baseIssues);
          console.log(this.headIssues);
          console.log(this.resolvedIssues);

          this.loadFailed = false;
          this.loadingMetrics = false;
        });
      });
    }, 
    loadUrl(url, callback) {
      $.ajax({
        context: this,
        type: "get",
        url: url,
        success: callback,
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
      <div
        v-if="shouldShowCodeQuality">
        <div v-if="newIssues.length">
          <p>Issues introduced in this merge request:</p>
          <ul>
            <li v-for="issue in newIssues">
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
        </div>
        <div v-if="resolvedIssues.length">
          <p>Issues resolved in this merge request:</p>
          <ul>
            <li v-for="issue in resolvedIssues">
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
        </div>
      </div>
      <p
        v-if="shouldShowLoadFailure">
        Failed to load codeclimate report.
      </p>
    </section>
  `,
};
