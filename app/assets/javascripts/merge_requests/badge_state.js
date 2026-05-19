import { observable } from '~/lib/utils/observable';

export const badgeState = observable('mr_badge_state', {
  state: '',
  updateStatus: null,
});
