/* global Vue, VueResource, Flash */

(() => {
  gl.VueIssueTitle = Vue.extend({
    props: [
      'initialTitle',
      'endpoint'
    ],
    data() {
      return {
        intervalId: '',
        title: this.initialTitle,
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
            this.$http.get(this.endpoint)
              .then((res) => {
                Vue.activeResources = 0;
                let title = JSON.parse(res.body).title;
                if (this.title === title) {
                  return;
                }
                this.$el.style.opacity = 0;
                setTimeout(() => {
                  this.title = title;
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
