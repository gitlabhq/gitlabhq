<script>
import { captureException } from '~/sentry/sentry_browser_wrapper';
import { I18N_ROLE_SAVE_SUCCESS, I18N_ROLE_SAVE_ERROR } from '~/members/constants';
import { callRoleUpdateApi, setMemberRole } from './utils';

export default {
  props: {
    member: {
      type: Object,
      required: true,
    },
    role: {
      type: Object,
      required: true,
    },
  },
  methods: {
    async saveRole() {
      try {
        this.emitBusy(true);
        this.emitAlert(null);

        await callRoleUpdateApi(this.member, this.role);

        setMemberRole(this.member, this.role);
        this.emitAlert({ message: I18N_ROLE_SAVE_SUCCESS, variant: 'success' });
      } catch (error) {
        captureException(error);
        this.emitAlert({
          message: error.response?.data?.message || I18N_ROLE_SAVE_ERROR,
          variant: 'danger',
          dismissible: false,
        });
      } finally {
        this.emitBusy(false);
      }
    },
    emitBusy(isBusy) {
      this.$emit('busy', isBusy);
    },
    emitAlert(alert) {
      this.$emit('alert', alert);
    },
  },
  render() {
    return this.$scopedSlots.default({
      saveRole: this.saveRole,
    });
  },
};
</script>
