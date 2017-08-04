import CEGetStateKey from '~/vue_merge_request_widget/stores/get_state_key';

export default function (data) {
  if (this.isGeoSecondaryNode) {
    return 'geoSecondaryNode';
  }

  if (this.shouldBeRebased) {
    return 'rebase';
  }

  return CEGetStateKey.call(this, data);
}

