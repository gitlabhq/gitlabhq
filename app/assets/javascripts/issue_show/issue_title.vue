<script>
import Visibility from 'visibilityjs';
import Poll from './../lib/utils/poll';
import Service from './services/index';

export default {
  props: {
    initialTitle: { required: true, type: String },
    endpoint: { required: true, type: String },
  },
  data() {
    const resource = new Service(this.$http, this.endpoint);

    const poll = new Poll({
      resource,
      method: 'getTitle',
      successCallback: (res) => {
        this.renderResponse(res);
      },
      errorCallback: (err) => {
        if (process.env.NODE_ENV !== 'production') {
          // eslint-disable-next-line no-console
          console.error('ISSUE SHOW TITLE REALTIME ERROR', err);
        } else {
          throw new Error(err);
        }
      },
    });

    return {
      poll,
      timeoutId: null,
      title: this.initialTitle,
    };
  },
  methods: {
    fetch() {
      this.poll.makeRequest();

      Visibility.change(() => {
        if (!Visibility.hidden()) {
          this.poll.restart();
        } else {
          this.poll.stop();
        }
      });
    },
    renderResponse(res) {
      const body = JSON.parse(res.body);
      this.triggerAnimation(body);
    },
    triggerAnimation(body) {
      const { title } = body;

      /**
      * since opacity is changed, even if there is no diff for Vue to update
      * we must check the title even on a 304 to ensure no visual change
      */
      if (this.title === title) return;

      this.$el.style.opacity = 0;

      this.timeoutId = setTimeout(() => {
        this.title = title;

        this.$el.style.transition = 'opacity 0.2s ease';
        this.$el.style.opacity = 1;

        clearTimeout(this.timeoutId);
      }, 100);
    },
  },
  created() {
    this.fetch();
  },
};
</script>

<template>
  <h2 class="title" v-html="title"></h2>
</template>
