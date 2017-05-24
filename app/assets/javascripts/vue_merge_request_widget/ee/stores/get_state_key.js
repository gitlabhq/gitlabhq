import CEGetStateKey from '../../stores/get_state_key';

export default function (data) {
  if (this.isGeoSecondaryNode) {
    return 'geoSecondaryNode';
  }

  if (this.shouldBeRebased) {
    return 'rebase';
  }

  return CEGetStateKey.call(this, data);
}

