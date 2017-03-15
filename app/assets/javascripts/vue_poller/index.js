const Vue = require('vue');
const VueResource = require('vue-resource');
const VueRealtimeListener = require('../vue_realtime_listener/index');

class VueShortPoller {
  constructor(options) {
    Vue.use(VueResource);

    this.options = options;
    this.state = {
      pollId: null,
      polling: false,
    };

    this.poll = this.poll.bind(this);
    this.removePoll = this.removePoll.bind(this);
    this.run = this.run.bind(this);
  }

  poll() {
    const { time } = this.options;
    this.state.pollId = setInterval(() => {
      const { polling } = this.state;
      return polling ? null : this.fetchData(this.options);
    }, time);
  }

  removePoll() {
    clearInterval(this.state.pollId);
  }

  fetchData({ url, data = {}, success, error }) {
    const lastFetchedAt = new Date();

    Object.assign(data, {
      headers: { 'X-Last-Fetched-At': lastFetchedAt },
    });

    this.state.polling = true;

    Vue.http.get(url, data)
      .then((res) => {
        success(res);
      })
      .then(() => {
        this.state.polling = false;
      })
      .catch((err) => {
        this.removePoll();
        error(err);
      });
  }

  run() {
    this.poll();
    VueRealtimeListener(this.removePoll, this.poll);
  }
}

module.exports = VueShortPoller;
