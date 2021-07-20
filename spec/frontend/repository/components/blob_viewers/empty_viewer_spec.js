import { shallowMount } from '@vue/test-utils';
import EmptyViewer from '~/repository/components/blob_viewers/empty_viewer.vue';

describe('Empty Viewer', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = shallowMount(EmptyViewer);
  });

  it('matches the snapshot', () => {
    expect(wrapper.element).toMatchSnapshot();
  });
});
