/*= require vue */
/*= require vue-resource */

/*= require boards/vue_resource_interceptor */
/*= require vue_realtime_listener/index */

/* global Vue, VueResource, Flash */

/** this needs to be disabled because this is the property provided by Vue */
/* eslint-disable no-underscore-dangle */

(() => {
  Vue.use(VueResource);

  Vue.http.headers.put['X-CSRF-token'] = document
    .querySelector('meta[name="csrf-token"]').content;

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
      };
    },
    created() {
      this.fetch();
    },
    computed: {
      titleMessage() {
        return this.htmlTitle ? this.htmlTitle : this.rubyTitle;
      },
      diff() {
        return this.diffTitle ? this.diffTitle : this.rubyDiffTitle;
      },
    },
    methods: {
      fetch() {
        this.intervalId = setInterval(() => {
          this.$http.get(this.endpoint)
            .then((res) => {
              const issue = JSON.parse(res.body);
              const { title } = issue;
              if (this.diff !== title) {
                this.diffTitle = title;
                this.mdToHtml(title, this.projectPath);
              }
            }, () => new Flash('Something went wrong on our end.'));
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
            }, 100);
          }, () => new Flash('Something went wrong on our end.'));
      },
      clear() {
        clearInterval(this.intervalId);
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
