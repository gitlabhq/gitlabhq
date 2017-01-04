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
                this.pageRequest = true;
                const body = JSON.parse(res.body);
                const { changed } = body;
                this.endOfCall();
                if (changed) {
                  const { title, digest } = body;
                  this.titleDigest = digest;
                  this.$el.style.opacity = 0;
                  setTimeout(() => {
                    this.title = title;
                    this.$el.style.transition = 'opacity 0.2s ease';
                    this.$el.style.opacity = 1;
                  }, 100);
                }
              }, () => this.endOfCall());
          }
        }, 3000);
      },
      clear() {
        clearInterval(this.intervalId);
      },
      endOfCall() {
        this.pageRequest = false;
        Vue.activeResources = 0;
      },
    },
    template: `
      <h2 class='title' v-html='title'></h2>
    `,
  });
})();

