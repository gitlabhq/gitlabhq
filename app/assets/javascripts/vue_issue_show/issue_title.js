const VuePoller = require('../vue_poller/index');

module.exports = {
  props: {
    initialTitle: { required: true, type: String },
    endpoint: { required: true, type: String },
  },
  data() {
    return {
      intervalId: '',
      title: this.initialTitle,
    };
  },
  created() {
    this.fetch();
  },
  methods: {
    fetch() {
      return new VuePoller({
        url: this.endpoint,
        time: 3000,
        success: (res) => { this.renderResponse(res); },
        error: (err) => { throw Error(err); },
      }).run();
    },
    renderResponse(res) {
      const body = JSON.parse(res.body);
      this.triggerAnimation(body);
    },
    triggerAnimation(body) {
      const { title } = body;
      if (this.title === title) return;

      this.$el.style.opacity = 0;

      setTimeout(() => {
        this.title = title;
        this.$el.style.transition = 'opacity 0.2s ease';
        this.$el.style.opacity = 1;
      }, 100);
    },
  },
  template: `
    <h2 class='title' v-html='title'></h2>
  `,
};
