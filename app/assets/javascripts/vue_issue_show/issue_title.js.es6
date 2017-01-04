/* global Vue, VueResource, Flash */

(() => {
  gl.VueIssueTitle = Vue.extend({
    props: [
      'rubyTitle',
      'endpoint',
      'projectPath',
      'rubyDiffTitle',
      'user',
    ],
    data() {
      return {
        intervalId: '',
        htmlTitle: '',
        diffTitle: '',
        failedCount: 0,
        pageRequest: false,
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
        if (this.user) {
          Vue.activeResources = 1;
          this.intervalId = setInterval(() => {
            if (!this.pageRequest) {
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
                }, () => this.onError());
            }
          }, 3000);
        }
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
          }, () => this.onError());
      },
      clear() {
        if (this.user) clearInterval(this.intervalId);
      },
      onError(reason) {
        this.pageRequest = false;
        Vue.activeResources = 0;
      },
    },
    template: `
      <h2 class='title' v-html='titleMessage'></h2>
    `,
  });
})();
