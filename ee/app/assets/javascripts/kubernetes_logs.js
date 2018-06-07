import $ from 'jquery';
import axios from '~/lib/utils/axios_utils';
import { getParameterValues } from '~/lib/utils/url_utility';
import { isScrolledToBottom, scrollDown, toggleDisableButton } from '~/lib/utils/scroll_utils';
import LogOutputBehaviours from '~/lib/utils/logoutput_behaviours';
import createFlash from '~/flash';
import { __, s__, sprintf } from '~/locale';
import _ from 'underscore';

export default class KubernetesPodLogs extends LogOutputBehaviours {
  constructor(container) {
    super();
    this.options = $(container).data();
    this.podNameContainer = $(container).find('.js-pod-name');
    this.podName = getParameterValues('pod_name')[0];
    this.$buildOutputContainer = $(container).find('.js-build-output');
    this.$window = $(window);
    this.$refreshLogBtn = $(container).find('.js-refresh-log');
    this.$buildRefreshAnimation = $(container).find('.js-build-refresh');
    this.isLogComplete = false;

    this.scrollThrottled = _.throttle(this.toggleScroll.bind(this), 100);

    if (!this.podName) {
      createFlash(s__('Environments|No pod name has been specified'));
      return;
    }

    const podTitle = sprintf(
      s__('Environments|Pod logs from %{podName}'),
      {
        podName: `<strong>${_.escape(this.podName)}</strong>`,
      },
      false,
    );
    this.podNameContainer.empty();
    this.podNameContainer.append(podTitle);

    this.$window.off('scroll').on('scroll', () => {
      if (!isScrolledToBottom()) {
        this.toggleScrollAnimation(false);
      } else if (isScrolledToBottom() && !this.isLogComplete) {
        this.toggleScrollAnimation(true);
      }
      this.scrollThrottled();
    });

    this.$refreshLogBtn.off('click').on('click', this.getPodLogs.bind(this));
  }

  scrollToBottom() {
    scrollDown();
    this.toggleScroll();
  }

  scrollToTop() {
    $(document).scrollTop(0);
    this.toggleScroll();
  }

  getPodLogs() {
    this.scrollToTop();
    this.$buildOutputContainer.empty();
    this.$buildRefreshAnimation.show();
    toggleDisableButton(this.$refreshLogBtn, 'true');

    return axios
      .get(this.options.logsPath, {
        params: { pod_name: this.podName },
      })
      .then(res => {
        const logs = res.data.logs;
        const formattedLogs = logs.map(logEntry => `${_.escape(logEntry)} <br />`);
        this.$buildOutputContainer.append(formattedLogs);
        scrollDown();
        this.isLogComplete = true;
        this.$buildRefreshAnimation.hide();
        toggleDisableButton(this.$refreshLogBtn, false);
      })
      .catch(() => createFlash(__('Something went wrong on our end')));
  }
}
