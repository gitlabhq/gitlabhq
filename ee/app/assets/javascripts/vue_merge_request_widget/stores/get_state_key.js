import CEGetStateKey from '~/vue_merge_request_widget/stores/get_state_key';

export default function (data) {
  if (this.isGeoSecondaryNode) {
    return 'geoSecondaryNode';
  }

  return CEGetStateKey.call(this, data);
}

