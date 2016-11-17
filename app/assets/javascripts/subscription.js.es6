/* global Vue */

((global) => {
  class Subscription {
    constructor(containerSelector) {
      this.containerElm = (typeof containerSelector === 'string')
        ? document.querySelector(containerSelector)
        : containerSelector;

      const subscribeButton = this.containerElm.querySelector('.js-subscribe-button');
      if (subscribeButton) {
        // remove class so we don't bind twice
        subscribeButton.classList.remove('js-subscribe-button');
        subscribeButton.addEventListener('click', this.toggleSubscription.bind(this));
      }
    }

    toggleSubscription(event) {
      const button = event.currentTarget;
      const buttonSpan = button.querySelector('span');
      if (!buttonSpan || button.classList.contains('disabled')) {
        return;
      }
      button.classList.add('disabled');

      const isSubscribed = buttonSpan.innerHTML.trim() !== 'Subscribe';
      const toggleActionUrl = this.containerElm.getAttribute('data-url');

      $.post(toggleActionUrl, () => {
        button.classList.remove('disabled');

        // hack to allow this to work with the issue boards Vue object
        if (document.querySelector('html').classList.contains('issue-boards-page')) {
          Vue.set(
            gl.issueBoards.BoardsStore.detail.issue,
            'subscribed',
            !gl.issueBoards.BoardsStore.detail.issue.subscribed
          );
        } else {
          const newToggleText = isSubscribed ? 'Subscribe' : 'Unsubscribe';
          buttonSpan.innerHTML = newToggleText;

          if (button.getAttribute('data-original-title')) {
            button.setAttribute('data-original-title', newToggleText);
            $(button).tooltip('hide').tooltip('fixTitle');
          }
        }
      });
    }

    static bindAll(selector) {
      [].forEach.call(document.querySelectorAll(selector), elm => new Subscription(elm));
    }
  }

  // eslint-disable-next-line no-param-reassign
  global.Subscription = Subscription;
})(window.gl || (window.gl = {}));
