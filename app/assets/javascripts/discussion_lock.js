class DiscussionLock {
  constructor(containerElm) {
    this.containerElm = containerElm;

    const lockButton = containerElm.querySelector('.js-discussion-lock-button');
    console.log(lockButton);
    if (lockButton) {
      // remove class so we don't bind twice
      lockButton.classList.remove('js-discussion-lock-button');
      console.log(lockButton);
      lockButton.addEventListener('click', this.toggleDiscussionLock.bind(this));
    }
  }

  toggleDiscussionLock(event) {
    const button = event.currentTarget;
    const buttonSpan = button.querySelector('span');
    if (!buttonSpan || button.classList.contains('disabled')) {
      return;
    }
    button.classList.add('disabled');

    const url = this.containerElm.dataset.url;
    const lock = this.containerElm.dataset.lock;
    const issuableType = this.containerElm.dataset.issuableType;

    const data = {}
    data[issuableType] = {}
    data[issuableType].discussion_locked = lock

    $.ajax({
      url,
      data: data,
      type: 'PUT'
    }).done((data) => {
      button.classList.remove('disabled');
    });
  }

  static bindAll(selector) {
    [].forEach.call(document.querySelectorAll(selector), elm => new DiscussionLock(elm));
  }
}

window.gl = window.gl || {};
window.gl.DiscussionLock = DiscussionLock;
