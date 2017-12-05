import CESidebarStore from '~/sidebar/stores/sidebar_store';

export default class SidebarStore extends CESidebarStore {
  constructor(store) {
    super(store);

    this.isFetching.weight = true;
    this.isLoading.weight = false;
    this.weight = null;
    this.weightOptions = store.weightOptions;
    this.weightNoneValue = store.weightNoneValue;
  }

  setWeightData(data) {
    this.isFetching.weight = false;
    this.weight = data.weight || null;
  }

  setWeight(newWeight) {
    this.weight = newWeight;
  }
}
