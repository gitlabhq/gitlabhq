/* global Vue, VueResource, Flash */

(() => {
  gl.VueIssueTitle = Vue.extend({
    props: [
      'initialTitle',
      'endpoint',
      'initialTitleDigest',
      'notUser',
    ],
    data() {
      return {
        intervalId: '',
        title: this.initialTitle,
        titleDigest: this.initialTitleDigest,
      };
    },
    created() {
      if (this.notUser === 'false') this.fetch();
    },
    methods: {
      fetch() {
        this.intervalId = setInterval(() => {
          if (Vue.activeResources === 0) {
            this.$http
              .get(this.endpoint, { params: { digest: this.titleDigest } })
                .then(res => this.renderResponse(res))
                .catch((err) => { throw new Error(err); });
          }
        }, 3000);
      },
      clear() {
        clearInterval(this.intervalId);
      },
      renderResponse(res) {
        const body = JSON.parse(res.body);
        this.triggerAnimation(body.changed, body);
      },
      triggerAnimation(changed, body) {
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
      },
    },
    template: `
      <h2 class='title' v-html='title'></h2>
    `,
  });
})();

