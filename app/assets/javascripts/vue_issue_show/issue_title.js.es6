/* global Vue, VueResource, Flash */

(() => {
  gl.VueIssueTitle = Vue.extend({
    props: [
      'initialTitle',
      'endpoint',
      'initialTitleDigest',
    ],
    data() {
      return {
        intervalId: '',
        title: this.initialTitle,
        titleDigest: this.initialTitleDigest,
        failedCount: 0,
        pageRequest: false,
      };
    },
    created() {
      this.fetch();
    },
    methods: {
      fetch() {
        Vue.activeResources = 1;
        this.intervalId = setInterval(() => {
          if (!this.pageRequest) {
            this.$http.get(this.endpoint, { params: { digest: this.titleDigest } })
              .then((res) => {
                Vue.activeResources = 0;
                let body = JSON.parse(res.body);
                if (!body.changed) {
                  return;
                }
                this.titleDigest = body.digest;
                this.$el.style.opacity = 0;
                setTimeout(() => {
                  this.title = body.title;
                  this.$el.style.transition = 'opacity 0.2s ease';
                  this.$el.style.opacity = 1;
                }, 100);
              }, () => this.onError());
          }
        }, 3000);
      },
      clear() {
        clearInterval(this.intervalId);
      },
      onError() {
        this.pageRequest = false;
        Vue.activeResources = 0;
      },
    },
    template: `
      <h2 class='title' v-html='title'></h2>
    `,
  });
})();
