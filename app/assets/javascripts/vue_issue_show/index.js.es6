/*= require vue */
/*= require vue-resource */

/* global Vue, VueResource, Flash */

(() => {
  Vue.use(VueResource);

  gl.VueIssueTitle = Vue.extend({
    props: ['rubyTitle', 'endpoint'],
    data() {
      return {
        intervalId: '',
        title: '',
        updatedAt: '',
      };
    },
    created() {
      this.fetch();
    },
    computed: {
      titleMessage() {
        if (this.rubyTitle) return this.rubyTitle;
        if (this.title) return this.title;
        return 'No Title For This Issue';
      },
    },
    methods: {
      fetch() {
        this.intervalId = setInterval(() => {
          this.$http.get(this.endpoint)
            .then((res) => {
              const issue = JSON.parse(res.body);
              if (this.updatedAt !== issue.updated_at) {
                this.updatedAt = issue.updated_at;
                this.title = issue.title;
              }
            }, () => {
              const flash = new Flash('Something went wrong updating the title');
              return flash;
            });
        }, 3000);
      },
      clear() {
        clearInterval(this.intervalId);
      },
    },
    template: `
      <h2 class='title'>
        {{titleMessage}}
      </h2>
    `,
  });

  const vm = new Vue({
    el: '.issue-title-vue',
    components: {
      'vue-title': gl.VueIssueTitle,
    },
    data() {
      return {
        rubyTitle: document.querySelector('.vue-data').dataset.rubyTitle,
        endpoint: document.querySelector('.vue-data').dataset.endpoint,
      };
    },
    template: `
      <div>
        <vue-title :rubyTitle='rubyTitle' :endpoint='endpoint'></vue-title>
      </div>
    `,
  });

  const titleComp = vm.$children
    .filter(e => e.$options._componentTag === 'vue-title')[0];

  const startTitleFetch = () => {
    titleComp.fetch();
  };

  const removeTimeIntervals = () => {
    titleComp.clear();
  };

  const startIntervalLoops = () => {
    startTitleFetch();
  };

  const removeAll = () => {
    window.removeEventListener('beforeunload', removeTimeIntervals);
    window.removeEventListener('focus', startIntervalLoops);
    window.removeEventListener('blur', removeTimeIntervals);

    // turbolinks event handler
    document.removeEventListener('page:fetch', () => {});
  };

  window.addEventListener('beforeunload', removeTimeIntervals);
  window.addEventListener('focus', startIntervalLoops);
  window.addEventListener('blur', removeTimeIntervals);

  // turbolinks event handler
  document.addEventListener('page:fetch', removeAll);
})(window.gl || (window.gl = {}));
