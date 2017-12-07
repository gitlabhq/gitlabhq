import CESidebarStore from '~/sidebar/stores/sidebar_store';

export default class SidebarStore extends CESidebarStore {
  initSingleton(options) {
    super.initSingleton(options);

    this.isFetching.weight = true;
    this.isFetching.epic = true;
    this.isLoading.weight = false;
    this.weight = null;
    this.weightOptions = options.weightOptions;
    this.weightNoneValue = options.weightNoneValue;
    this.epic = {};
  }

  setWeightData(data) {
    this.isFetching.weight = false;
    this.weight = data.weight || null;
  }

  setWeight(newWeight) {
    this.weight = newWeight;
  }

  setEpicData(data) {
    this.isFetching.epic = false;
    this.epic = data.epic || {};
  }
}
