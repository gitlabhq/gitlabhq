const Vue = require('vue');
const VueResource = require('vue-resource');
const VueRealtimeListener = require('../vue_realtime_listener/index');

Vue.use(VueResource);

const NO_CHANGE = status => (status === 304);

class VueShortPoller {
  constructor(options) {
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
    this.state.polling = true;

    Vue.http.get(url, data)
      .then((res) => {
        const { status } = res;
        return NO_CHANGE(status) ? null : success(res);
      })
      .then(() => {
        this.state.polling = false;
      })
      .catch((err) => {
        this.state.polling = false;
        this.removePoll();
        error(err);
      });
  }

  run() {
    VueRealtimeListener(this.removePoll, this.poll);
  }
}

module.exports = VueShortPoller;
