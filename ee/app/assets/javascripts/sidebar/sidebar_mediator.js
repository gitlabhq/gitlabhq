import CESidebarMediator from '~/sidebar/sidebar_mediator';
import Store from 'ee/sidebar/stores/sidebar_store';

export default class SidebarMediator extends CESidebarMediator {
  initSingleton(options) {
    super.initSingleton(options);
    this.store = new Store(options);
  }

  processFetchedData(data) {
    super.processFetchedData(data);
    this.store.setWeightData(data);
    this.store.setEpicData(data);
  }

  updateWeight(newWeight) {
    this.store.setLoadingState('weight', true);
    return this.service.update('issue[weight]', newWeight)
      .then(res => res.json())
      .then((data) => {
        this.store.setWeight(data.weight);
        this.store.setLoadingState('weight', false);
      })
      .catch((err) => {
        this.store.setLoadingState('weight', false);
        throw err;
      });
  }
}
