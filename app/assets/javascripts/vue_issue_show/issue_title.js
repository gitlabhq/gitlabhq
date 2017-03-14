const VuePoller = require('../vue_poller/index');

module.exports = {
  props: {
    initialTitle: { required: true, type: String },
    endpoint: { required: true, type: String },
    initialTitleDigest: { required: true, type: String },
    notUser: { required: true, type: String },
  },
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
      const data = {
        params: { digest: this.titleDigest },
      };

      return new VuePoller({
        data,
        url: this.endpoint,
        time: 3000,
        success: this.renderResponse,
        error: (err) => { throw Error(err); },
      }).run();
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
};
