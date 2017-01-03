/*= require vue */
/*= require vue-resource */

/*= require vue_realtime_listener/index */

/* global Vue, VueResource, Flash */

/* eslint-disable no-underscore-dangle */

(() => {
  Vue.use(VueResource);

  /**
    not using vue_resource_interceptor because of the nested call to render html
    this requires a bit more custom logic
    specifically the 'if/else' in the 'fetch' method
  */
  Vue.activeResources = 0;

  const user = document.querySelector('meta[name="csrf-token"]');
  if (user) Vue.http.headers.post['X-CSRF-token'] = user.content;

  gl.VueIssueTitle = Vue.extend({
    props: [
      'rubyTitle',
      'endpoint',
      'projectPath',
      'rubyDiffTitle',
    ],
    data() {
      return {
        intervalId: '',
        htmlTitle: '',
        diffTitle: '',
        failedCount: 0,
      };
    },
    created() {
      this.fetch();
    },
    computed: {
      titleMessage() {
        const rubyTitle = `<p dir="auto">${this.rubyTitle}</p>`;
        return this.htmlTitle ? this.htmlTitle : rubyTitle;
      },
      diff() {
        return this.diffTitle ? this.diffTitle : this.rubyDiffTitle;
      },
    },
    methods: {
      fetch() {
        Vue.activeResources = 1;
        this.intervalId = setInterval(() => {
          this.$http.get(this.endpoint)
            .then((res) => {
              const issue = JSON.parse(res.body);
              const { title } = issue;
              if (this.diff !== title) {
                this.diffTitle = title;
                this.mdToHtml(title, this.projectPath);
              } else {
                Vue.activeResources = 0;
              }
            }, () => this.onError('attempting to check if there is a new title'));
        }, 3000);
      },
      mdToHtml(title, projectPath) {
        this.$http.post(`${projectPath}/preview_markdown`, { text: title })
          .then((res) => {
            this.$el.style.opacity = 0;
            setTimeout(() => {
              this.htmlTitle = JSON.parse(res.body).body;
              this.$el.style.transition = 'opacity 0.2s ease';
              this.$el.style.opacity = 1;
              Vue.activeResources = 0;
            }, 100);
          }, () => this.onError('trying to render the updated title'));
      },
      clear() {
        clearInterval(this.intervalId);
      },
      onError(reason) {
        /**
          When the API call fails to update in realtime,
          the interval is killed if more than 3 calls failed.
          the user is then instructed to refresh the page
        */
        this.failedCount = this.failedCount += 1;
        if (this.failedCount > 2) this.clear();
        Vue.activeResources = 0;
        return new Flash(`Something went wrong ${reason}. Refresh the page and try again.`);
      },
    },
    template: `
      <h2 class='title' v-html='titleMessage'></h2>
    `,
  });

  const vueData = document.querySelector('.vue-data').dataset;

  const vm = new Vue({
    el: '.issue-title-vue',
    components: {
      'vue-title': gl.VueIssueTitle,
    },
    data() {
      return {
        rubyTitle: vueData.rubyTitle,
        endpoint: vueData.endpoint,
        projectPath: vueData.projectPath,
        rubyDiffTitle: vueData.rubyDiffTitle,
      };
    },
    template: `
      <div>
        <vue-title
          :rubyTitle='rubyTitle'
          :endpoint='endpoint'
          :projectPath='projectPath'
          :rubyDiffTitle='rubyDiffTitle'
        >
        </vue-title>
      </div>
    `,
  });

  const titleComp = vm.$children
    .filter(e => e.$options._componentTag === 'vue-title')[0];

  const startTitleFetch = () => titleComp.fetch();
  const removeIntervalLoops = () => titleComp.clear();
  const startIntervalLoops = () => startTitleFetch();

  gl.VueRealtimeListener(removeIntervalLoops, startIntervalLoops);
})(window.gl || (window.gl = {}));
