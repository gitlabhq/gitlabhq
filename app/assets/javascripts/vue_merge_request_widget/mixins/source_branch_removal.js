import { InternalEvents } from '~/tracking';
import { createAlert } from '~/alert';
import { __ } from '~/locale';

export default {
  props: {
    service: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isMakingRequest: false,
    };
  },
  computed: {
    shouldShowRemoveSourceBranch() {
      return (
        !this.mr.sourceBranchRemoved &&
        this.mr.canRemoveSourceBranch &&
        !this.isMakingRequest &&
        !this.mr.isRemovingSourceBranch
      );
    },
  },
  methods: {
    removeSourceBranch(trackingEvent) {
      this.isMakingRequest = true;

      InternalEvents.trackEvent(trackingEvent);

      this.service
        .removeSourceBranch()
        .then((res) => res.data)
        .then((data) => {
          // False positive i18n lint: https://gitlab.com/gitlab-org/frontend/eslint-plugin-i18n/issues/26
          // eslint-disable-next-line @gitlab/require-i18n-strings
          if (data.message === 'Branch was deleted') {
            this.mr.sourceBranchRemoved = true;
          }
        })
        .catch(() => {
          createAlert({
            message: __('Something went wrong. Please try again.'),
          });
        })
        .finally(() => {
          this.isMakingRequest = false;
        });
    },
  },
};
