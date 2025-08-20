import Vue from 'vue';

export function initDuoPanel() {
  const el = document.getElementById('duo-chat-panel');

  if (!el) {
    return false;
  }

  return new Vue({
    el,
    data: () => {
      return {
        fullscreen: false,
      };
    },
    render(createElement) {
      return createElement(
        'div',
        {
          class: {
            'gl-pt-4 gl-bg-default gl-rounded-lg !gl-left-auto !gl-h-[100vh] gl-grow': true,
            fullscreen: this.fullscreen,
          },
        },
        [
          createElement(
            'div',
            {
              class: 'gl-p-5',
            },
            [
              // eslint-disable-next-line @gitlab/require-i18n-strings
              "Hi! Let's pretend I'm Duo Chat",
              createElement('br'),
              createElement(
                'button',
                {
                  on: {
                    click: () => {
                      this.fullscreen = !this.fullscreen;
                    },
                  },
                },
                // eslint-disable-next-line @gitlab/require-i18n-strings
                'Toggle Fullscreen mode',
              ),
            ],
          ),
        ],
      );
    },
  });
}
