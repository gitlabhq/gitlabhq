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
    const buttonSpan = button.querySelector('span');
    if (!buttonSpan || button.classList.contains('disabled')) {
      return;
    }
    button.classList.add('disabled');

    // hack to allow this to work with the issue boards Vue object
    const isBoardsPage = document.querySelector('html').classList.contains('issue-boards-page');

    const isSubscribed = buttonSpan.innerHTML.trim().toLowerCase() !== 'subscribe';
    let toggleActionUrl = this.containerElm.dataset.url;

    if (isBoardsPage) {
      toggleActionUrl = toggleActionUrl.replace(':project_path', gl.issueBoards.BoardsStore.detail.issue.project.path);
    }

    $.post(toggleActionUrl, () => {
      button.classList.remove('disabled');

      if (isBoardsPage) {
        gl.issueBoards.boardStoreIssueSet(
          'subscribed',
          !gl.issueBoards.BoardsStore.detail.issue.subscribed,
        );
      } else {
        buttonSpan.innerHTML = isSubscribed ? 'Subscribe' : 'Unsubscribe';
      }
    });
  }

  static bindAll(selector) {
    [].forEach.call(document.querySelectorAll(selector), elm => new Subscription(elm));
  }
}

window.gl = window.gl || {};
window.gl.Subscription = Subscription;
