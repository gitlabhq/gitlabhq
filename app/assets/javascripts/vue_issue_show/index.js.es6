/*= require vue */
/*= require vue-resource */

/*= require boards/vue_resource_interceptor */

/* global Vue, VueResource, Flash */

/** this needs to be disabled because this is the property provided by Vue */
/* eslint-disable no-underscore-dangle */

(() => {
  Vue.use(VueResource);

  gl.VueIssueTitle = Vue.extend({
    props: ['rubyTitle', 'endpoint'],
    data() {
      return {
        intervalId: '',
        title: '',
      };
    },
    created() {
      this.fetch();
    },
    computed: {
      titleMessage() {
        if (this.rubyTitle && !this.title) return this.rubyTitle;
        return this.title;
      },
    },
    methods: {
      fetch() {
        this.intervalId = setInterval(() => {
          this.$http.get(this.endpoint)
            .then((res) => {
              const issue = JSON.parse(res.body);
              if (this.titleMessage !== issue.title) {
                this.$el.style.opacity = 0;
                setTimeout(() => {
                  this.title = issue.title;
                  this.$el.style.transition = 'opacity 0.2s ease';
                  this.$el.style.opacity = 1;
                }, 100);
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

  const removeIntervalLoops = () => {
    titleComp.clear();
  };

  const startIntervalLoops = () => {
    startTitleFetch();
  };

  const removeAll = () => {
    window.removeEventListener('beforeunload', removeIntervalLoops);
    window.removeEventListener('focus', startIntervalLoops);
    window.removeEventListener('blur', removeIntervalLoops);

    // turbolinks event handler
    document.removeEventListener('page:fetch', () => {});
  };

  window.addEventListener('beforeunload', removeIntervalLoops);
  window.addEventListener('focus', startIntervalLoops);
  window.addEventListener('blur', removeIntervalLoops);

  // turbolinks event handler
  document.addEventListener('page:fetch', removeAll);
})(window.gl || (window.gl = {}));
