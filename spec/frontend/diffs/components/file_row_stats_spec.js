import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import FileRowStats from '~/diffs/components/file_row_stats.vue';

describe('Diff file row stats', () => {
  let wrapper;

  const findAdded = () => wrapper.findByTestId('file-added-lines');
  const findRemoved = () => wrapper.findByTestId('file-removed-lines');

  const createComponent = (file) => {
    wrapper = shallowMountExtended(FileRowStats, { propsData: { file } });
  };

  it('renders added and removed lines count', () => {
    createComponent({ addedLines: 20, removedLines: 10 });

    expect(findAdded().text()).toBe('+20');
    expect(findRemoved().text()).toBe('-10');
  });

  it('omits the removed count when no lines were removed', () => {
    createComponent({ addedLines: 20, removedLines: 0 });

    expect(findAdded().text()).toBe('+20');
    expect(findRemoved().exists()).toBe(false);
  });

  it('omits the added count when no lines were added', () => {
    createComponent({ addedLines: 0, removedLines: 10 });

    expect(findAdded().exists()).toBe(false);
    expect(findRemoved().text()).toBe('-10');
  });
});
