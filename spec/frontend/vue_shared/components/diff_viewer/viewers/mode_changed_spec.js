import { shallowMount } from '@vue/test-utils';
import ModeChanged from '~/vue_shared/components/diff_viewer/viewers/mode_changed.vue';

describe('Diff viewer mode changed component', () => {
  let vm;

  beforeEach(() => {
    vm = shallowMount(ModeChanged, {
      propsData: {
        aMode: '123',
        bMode: '321',
      },
    });
  });

  it('renders aMode & bMode', () => {
    expect(vm.text()).toContain('File mode changed from 123 to 321');
  });
});
