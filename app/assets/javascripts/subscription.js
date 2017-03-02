(() => {
  class Subscription {
    constructor(containerElm) {
      this.containerElm = containerElm;

      const subscribeButton = containerElm.querySelector('.js-subscribe-button');
      if (subscribeButton) {
        // remove class so we don't bind twice
        subscribeButton.classList.remove('js-subscribe-button');
        subscribeButton.addEventListener('click', this.toggleSubscription.bind(this));
      }
    }

    toggleSubscription(event) {
      const button = event.currentTarget;
      const toggleButton = $('.toggle-button');
      if (button.classList.contains('disabled')) {
        return;
      }
      button.classList.add('disabled');

      const toggleActionUrl = this.containerElm.dataset.url;

      $.post(toggleActionUrl, () => {
        button.classList.remove('disabled');
        toggleButton.toggleClass('subscribed unsubscribed');

        // hack to allow this to work with the issue boards Vue object
        if (document.querySelector('html').classList.contains('issue-boards-page')) {
          gl.issueBoards.boardStoreIssueSet(
            'subscribed',
            !gl.issueBoards.BoardsStore.detail.issue.subscribed,
          );
        }
      });
    }

    static bindAll(selector) {
      [].forEach.call(document.querySelectorAll(selector), elm => new Subscription(elm));
    }
  }

  window.gl = window.gl || {};
  window.gl.Subscription = Subscription;
})();
