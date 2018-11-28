import axios from '~/lib/utils/axios_utils';

const DEFAULT_LIMIT = 20;

export default class UserOverviewBlock {
  constructor(options = {}) {
    this.container = options.container;
    this.url = options.url;
    this.requestParams = {
      limit: DEFAULT_LIMIT,
      ...options.requestParams,
    };
    this.postRenderCallback = options.postRenderCallback;
    this.loadData();
  }

  loadData() {
    const loadingEl = document.querySelector(`${this.container} .loading`);

    loadingEl.classList.remove('hide');

    axios
      .get(this.url, {
        params: this.requestParams,
      })
      .then(({ data }) => this.render(data))
      .catch(() => loadingEl.classList.add('hide'));
  }

  render(data) {
    const { html, count } = data;
    const contentList = document.querySelector(`${this.container} .overview-content-list`);

    contentList.innerHTML += html;

    const loadingEl = document.querySelector(`${this.container} .loading`);

    if (count && count > 0) {
      document.querySelector(`${this.container} .js-view-all`).classList.remove('hide');
    } else {
      document
        .querySelector(`${this.container} .nothing-here-block`)
        .classList.add('text-left', 'p-0');
    }

    loadingEl.classList.add('hide');

    if (this.postRenderCallback) {
      this.postRenderCallback.call(this);
    }
  }
}
