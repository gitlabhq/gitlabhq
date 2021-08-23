import { shallowMount } from '@vue/test-utils';
import StorageCounterApp from '~/projects/storage_counter/components/app.vue';

describe('Storage counter app', () => {
  let wrapper;

  const createComponent = (propsData = {}) => {
    wrapper = shallowMount(StorageCounterApp, { propsData });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders app successfully', () => {
    expect(wrapper.text()).toBe('Usage');
  });
});
